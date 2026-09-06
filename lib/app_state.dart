import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

const _alertHistoryKey = 'itantra.alerts.history';

enum AppTab { home, devices, settings }

final List<Map<LangCode, Phrase>> kPhrases = [
  {
    LangCode.en: const Phrase(native: 'Send medical supplies now', latin: 'Send medical supplies now'),
    LangCode.hi: const Phrase(native: 'अभी चिकित्सा सामग्री भेजें', latin: 'Abhi chikitsa samagri bhejein'),
    LangCode.ta: const Phrase(native: 'இப்போது மருத்துவ பொருட்களை அனுப்பவும்', latin: 'Ippodhu maruthuva porutkalai anuppavum'),
  },
  {
    LangCode.en: const Phrase(native: 'All clear, proceed to the shelter', latin: 'All clear, proceed to the shelter'),
    LangCode.hi: const Phrase(native: 'सब ठीक है, आश्रय की ओर बढ़ें', latin: 'Sab theek hai, aashray ki or badhein'),
    LangCode.ta: const Phrase(native: 'எல்லாம் சரி, தங்குமிடத்திற்கு செல்லுங்கள்', latin: 'Ellaam sari, thangumidathirku sellungal'),
  },
  {
    LangCode.en: const Phrase(native: 'Water levels rising, move to higher ground', latin: 'Water levels rising, move to higher ground'),
    LangCode.hi: const Phrase(native: 'पानी का स्तर बढ़ रहा है, ऊँची जगह जाएँ', latin: 'Paani ka star badh raha hai, oonchi jagah jaayein'),
    LangCode.ta: const Phrase(native: 'நீர் மட்டம் உயருகிறது, உயரமான இடத்திற்கு செல்லுங்கள்', latin: 'Neer mattam uyarugirathu, uyaramana idathirku sellungal'),
  },
  {
    LangCode.en: const Phrase(native: 'Team is on the way, hold position', latin: 'Team is on the way, hold position'),
    LangCode.hi: const Phrase(native: 'टीम रास्ते में है, स्थिति बनाए रखें', latin: 'Team raaste mein hai, sthiti banaaye rakhein'),
    LangCode.ta: const Phrase(native: 'குழு வழியில் உள்ளது, இடத்தில் இருங்கள்', latin: 'Kuzhu vazhiyil ullathu, idathil irungal'),
  },
];

final Map<LangCode, Phrase> kEmergencyMessage = {
  LangCode.en: const Phrase(native: 'Flash flood warning — evacuate to high ground immediately', latin: 'Flash flood warning — evacuate to high ground immediately'),
  LangCode.hi: const Phrase(native: 'बाढ़ की चेतावनी — तुरंत ऊँचाई की ओर जाएँ', latin: 'Baadh ki chetavani — turant oonchai ki or jaayein'),
  LangCode.ta: const Phrase(native: 'திடீர் வெள்ள எச்சரிக்கை — உடனடியாக உயரமான இடத்திற்கு செல்லவும்', latin: 'Thidir vella echcharikkai — udanadiyaaga uyaramaana idathirku sellavum'),
};

/// Mirrors the state machine from the new Claude Design prototype
/// (light theme, tab navigation), with the same simulated behavior.
/// Real STT/TTS/Bluetooth wiring replaces the simulation methods later.
class AppState extends ChangeNotifier {
  AppTab tab = AppTab.home;
  bool recording = false;

  List<Message> messages = [
    const Message(id: 1, dir: MsgDir.received, phraseIdx: 0, lang: LangCode.en, playing: false),
  ];
  int nextPhrase = 1;

  LangCode langMine = LangCode.en;
  LangCode langTheirs = LangCode.hi;
  ScriptMode scriptMode = ScriptMode.both;
  bool showLangSheet = false;

  double volume = 80;
  bool emergencyEnabled = true;
  bool showEmergency = false;
  double emergencyProgress = 0;
  bool emergencyDone = false;

  List<EmergencyAlertRecord> alertHistory = [];

  final List<Timer> _timers = [];

  AppState() {
    _loadAlertHistory();
  }

  Future<void> _loadAlertHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_alertHistoryKey) ?? [];
      alertHistory = raw.map((s) => EmergencyAlertRecord.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    } catch (_) {
      alertHistory = [];
    }
  }

  Future<void> _saveAlertHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_alertHistoryKey, alertHistory.map((a) => jsonEncode(a.toJson())).toList());
    } catch (_) {
      // Non-fatal: the log just won't persist across restarts this time.
    }
  }

  Timer _addTimer(Duration d, void Function() fn) {
    final t = Timer(d, fn);
    _timers.add(t);
    return t;
  }

  Message? get playingMessage {
    for (final m in messages) {
      if (m.playing) return m;
    }
    return null;
  }

  void setTab(AppTab t) {
    tab = t;
    showLangSheet = false;
    notifyListeners();
  }

  void startRecording() {
    if (showEmergency) return;
    recording = true;
    notifyListeners();
  }

  void stopRecording() {
    if (!recording) return;
    recording = false;
    final idx = nextPhrase;
    final msg = Message(id: DateTime.now().millisecondsSinceEpoch, dir: MsgDir.sent, phraseIdx: idx, lang: langMine);
    messages = [...messages, msg];
    nextPhrase = idx + 1;
    notifyListeners();
    _addTimer(const Duration(milliseconds: 1100), receiveReply);
  }

  void receiveReply() {
    final idx = nextPhrase;
    final id = DateTime.now().millisecondsSinceEpoch + 1;
    final msg = Message(id: id, dir: MsgDir.received, phraseIdx: idx, lang: langMine, playing: true);
    messages = [...messages, msg];
    nextPhrase = idx + 1;
    notifyListeners();
    _addTimer(const Duration(milliseconds: 2400), () => finishPlayback(id));
  }

  void finishPlayback(int id) {
    messages = [for (final m in messages) m.id == id ? m.copyWith(playing: false) : m];
    notifyListeners();
  }

  void replay(int id) {
    messages = [for (final m in messages) m.id == id ? m.copyWith(playing: true) : m];
    notifyListeners();
    _addTimer(const Duration(milliseconds: 2000), () => finishPlayback(id));
  }

  void forceIncoming() => receiveReply();

  void toggleScriptMode() {
    const order = [ScriptMode.both, ScriptMode.native, ScriptMode.latin];
    final i = order.indexOf(scriptMode);
    scriptMode = order[(i + 1) % order.length];
    notifyListeners();
  }

  void openLangSheet() {
    showLangSheet = true;
    notifyListeners();
  }

  void closeLangSheet() {
    showLangSheet = false;
    notifyListeners();
  }

  void selectMine(LangCode l) {
    langMine = l;
    notifyListeners();
  }

  void selectTheirs(LangCode l) {
    langTheirs = l;
    notifyListeners();
  }

  void swapLangs() {
    final tmp = langMine;
    langMine = langTheirs;
    langTheirs = tmp;
    notifyListeners();
  }

  void setVolume(double v) {
    volume = v;
    notifyListeners();
  }

  void toggleEmergencyEnabled() {
    emergencyEnabled = !emergencyEnabled;
    notifyListeners();
  }

  void triggerEmergency() {
    showEmergency = true;
    emergencyProgress = 0;
    emergencyDone = false;

    final msg = kEmergencyMessage[langMine] ?? kEmergencyMessage[LangCode.en]!;
    alertHistory = [
      EmergencyAlertRecord(id: DateTime.now().millisecondsSinceEpoch, dir: MsgDir.sent, native: msg.native, latin: msg.latin, timestamp: DateTime.now()),
      ...alertHistory,
    ];
    unawaited(_saveAlertHistory());

    notifyListeners();
    const duration = Duration(milliseconds: 3000);
    final start = DateTime.now();
    final iv = Timer.periodic(const Duration(milliseconds: 100), (t) {
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      final p = (elapsed / duration.inMilliseconds * 100).clamp(0, 100).toDouble();
      if (p >= 100) {
        t.cancel();
        emergencyProgress = 100;
        emergencyDone = true;
      } else {
        emergencyProgress = p;
      }
      notifyListeners();
    });
    _timers.add(iv);
  }

  void acknowledgeEmergency() {
    showEmergency = false;
    emergencyProgress = 0;
    emergencyDone = false;
    notifyListeners();
  }

  Phrase phraseFor(int phraseIdx, LangCode lang) => kPhrases[phraseIdx % kPhrases.length][lang]!;

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }
}
