import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'services/bluetooth_manager.dart';
import 'services/speech_recognition_service.dart';
import 'services/translation_service.dart';
import 'services/tts_service.dart';

const _alertHistoryKey = 'itantra.alerts.history';
const _emergencyModeKey = 'itantra.emergencyMode';
const _onboardingDoneKey = 'itantra.onboarding.done';
const _volumeKey = 'itantra.volume';

enum AppTab { home, broadcast, settings }

/// Live stage of the real STT → MT → Bluetooth-send pipeline for the
/// in-flight recording, shown as a stepper (see `home_screen.dart`).
enum PipelineStage { idle, listening, understanding, sending }

final Map<LangCode, Phrase> kEmergencyMessage = {
  LangCode.en: const Phrase(native: 'Flash flood warning — evacuate to high ground immediately', latin: 'Flash flood warning — evacuate to high ground immediately'),
  LangCode.hi: const Phrase(native: 'बाढ़ की चेतावनी — तुरंत ऊँचाई की ओर जाएँ', latin: 'Baadh ki chetavani — turant oonchai ki or jaayein'),
  LangCode.ta: const Phrase(native: 'திடீர் வெள்ள எச்சரிக்கை — உடனடியாக உயரமான இடத்திற்கு செல்லவும்', latin: 'Thidir vella echcharikkai — udanadiyaaga uyaramaana idathirku sellavum'),
};

/// Mirrors the state machine from the new Claude Design prototype (light
/// theme, tab navigation). Speech recognition, translation, TTS playback and
/// Bluetooth text transport are real (see services/), driven from here.
class AppState extends ChangeNotifier {
  AppTab tab = AppTab.home;
  bool recording = false;
  PipelineStage pipelineStage = PipelineStage.idle;

  /// Live partial transcript from Vosk while [recording] is true — updates
  /// continuously as the user speaks, before the utterance is finalized.
  /// See `speech_recognition_service.dart`'s `onPartial`.
  String partialTranscript = '';

  List<Message> messages = [];

  /// Maps a `BluetoothManager.sendText` protocol id to the [Message.id] it
  /// belongs to, so an ack on `messageAcked` can flip that message's
  /// [DeliveryStatus] to delivered.
  final Map<int, int> _pendingDeliveries = {};

  LangCode langMine = LangCode.en;
  LangCode langTheirs = LangCode.hi;
  bool showLangSheet = false;

  double volume = 80;
  bool emergencyEnabled = true;
  bool showEmergency = false;
  double emergencyProgress = 0;
  bool emergencyDone = false;

  List<EmergencyAlertRecord> alertHistory = [];

  /// When on: a persistent status banner shows on Home, and the decorative
  /// PTT pulse-ring animation is skipped (small real battery saving, not
  /// just a label) — see `home_screen.dart`/`conversation_screen.dart`.
  bool emergencyMode = false;

  bool onboardingDone;

  final List<Timer> _timers = [];

  final SpeechRecognitionService _stt = SpeechRecognitionService();
  final TranslationService _mt = TranslationService();
  final TtsService _tts = TtsService();
  BluetoothManager? _bt;
  StreamSubscription<IncomingMessage>? _incomingSub;
  StreamSubscription<int>? _acksSub;
  StreamSubscription<String>? _partialSub;

  AppState({this.onboardingDone = true}) {
    _loadAlertHistory();
    _loadEmergencyMode();
    _loadVolume();
    unawaited(_stt.preload(langMine));
    unawaited(_mt.preload(langMine, langTheirs));
    _partialSub = _stt.onPartial.listen((partial) {
      partialTranscript = partial;
      notifyListeners();
    });
  }

  Future<void> _loadVolume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble(_volumeKey);
      if (saved != null) {
        volume = saved;
        notifyListeners();
      }
    } catch (_) {
      // Non-fatal: defaults to 80.
    }
    unawaited(_tts.setVolume(volume / 100));
  }

  Future<void> _loadEmergencyMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      emergencyMode = prefs.getBool(_emergencyModeKey) ?? false;
      notifyListeners();
    } catch (_) {
      // Non-fatal: defaults to off.
    }
  }

  void toggleEmergencyMode() {
    emergencyMode = !emergencyMode;
    notifyListeners();
    unawaited(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_emergencyModeKey, emergencyMode);
      } catch (_) {
        // Non-fatal: the toggle just won't persist across restarts this time.
      }
    }());
  }

  void completeOnboarding() {
    onboardingDone = true;
    notifyListeners();
    unawaited(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_onboardingDoneKey, true);
      } catch (_) {
        // Non-fatal: onboarding just replays once more next launch.
      }
    }());
  }

  /// Links this state to the app's [BluetoothManager] so recognized/typed
  /// text gets sent, and incoming text drives TTS playback. Idempotent —
  /// safe to call on every rebuild of the widget that wires them together.
  void attachBluetooth(BluetoothManager bt) {
    if (identical(_bt, bt)) return;
    _bt = bt;
    unawaited(_incomingSub?.cancel());
    unawaited(_acksSub?.cancel());
    _incomingSub = bt.incomingText.listen(_onIncomingText);
    _acksSub = bt.messageAcked.listen(_onMessageAcked);
  }

  void _onMessageAcked(int btId) {
    final msgId = _pendingDeliveries.remove(btId);
    if (msgId == null) return;
    messages = [for (final m in messages) m.id == msgId ? m.copyWith(delivery: DeliveryStatus.delivered) : m];
    notifyListeners();
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
    if (showEmergency || recording || pipelineStage != PipelineStage.idle) return;
    recording = true;
    pipelineStage = PipelineStage.listening;
    partialTranscript = '';
    notifyListeners();
    unawaited(_stt.startListening(langMine));
  }

  void stopRecording() {
    if (!recording) return;
    recording = false;
    pipelineStage = PipelineStage.understanding;
    notifyListeners();
    unawaited(_finishRecording());
  }

  Future<void> _finishRecording() async {
    final recognized = await _stt.stopListening();
    partialTranscript = '';
    if (recognized.isEmpty) {
      pipelineStage = PipelineStage.idle;
      notifyListeners();
      return;
    }

    final msgId = DateTime.now().millisecondsSinceEpoch;
    final msg = Message(id: msgId, dir: MsgDir.sent, lang: langMine, text: recognized, delivery: DeliveryStatus.sending);
    messages = [...messages, msg];
    notifyListeners();

    final translated = await _mt.translate(recognized, from: langMine, to: langTheirs);
    pipelineStage = PipelineStage.sending;
    notifyListeners();

    final btId = await _bt?.sendText(translated, langTheirs);
    if (btId != null) _pendingDeliveries[btId] = msgId;

    pipelineStage = PipelineStage.idle;
    notifyListeners();
  }

  void sendTypedMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final msgId = DateTime.now().millisecondsSinceEpoch;
    final msg = Message(id: msgId, dir: MsgDir.sent, lang: langMine, text: trimmed, delivery: DeliveryStatus.sending);
    messages = [...messages, msg];
    notifyListeners();
    unawaited(_translateAndSend(msgId, trimmed));
  }

  Future<void> _translateAndSend(int msgId, String text) async {
    final translated = await _mt.translate(text, from: langMine, to: langTheirs);
    final btId = await _bt?.sendText(translated, langTheirs);
    if (btId != null) _pendingDeliveries[btId] = msgId;
  }

  /// Translates [text] from [langMine] to [langTheirs] without sending
  /// anything — lets the user (or a connectionless device) see what a
  /// message would say on the other end before a peer is even connected.
  Future<String> previewTranslation(String text) => _mt.translate(text, from: langMine, to: langTheirs);

  /// Called when a message arrives over Bluetooth — already translated by
  /// the sender, tagged with the language it's actually written in (not
  /// assumed from our own [langMine], so playback is correct even if the
  /// two phones' language pairs aren't perfectly mirrored).
  void _onIncomingText(IncomingMessage incoming) {
    final text = incoming.text;
    final lang = incoming.lang;
    final id = DateTime.now().millisecondsSinceEpoch + 1;
    final msg = Message(id: id, dir: MsgDir.received, lang: lang, text: text, playing: true);
    messages = [...messages, msg];
    notifyListeners();
    unawaited(_tts.speak(text, lang, onDone: () => finishPlayback(id)));
  }

  void finishPlayback(int id) {
    messages = [for (final m in messages) m.id == id ? m.copyWith(playing: false) : m];
    notifyListeners();
  }

  void replay(int id) {
    final matches = messages.where((m) => m.id == id);
    if (matches.isEmpty) return;
    final msg = matches.first;
    messages = [for (final m in messages) m.id == id ? m.copyWith(playing: true) : m];
    notifyListeners();
    unawaited(_tts.speak(msg.text, msg.lang, onDone: () => finishPlayback(id)));
  }

  /// Speaks [text] live in [langMine] — used by the typed-message bar's
  /// preview button to hear a draft read back before sending, and by the
  /// Broadcast screen's "Speak instead" affordance.
  void speakPreview(String text) {
    unawaited(_tts.speak(text, langMine));
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
    unawaited(_stt.preload(langMine));
    unawaited(_mt.preload(langMine, langTheirs));
  }

  void selectTheirs(LangCode l) {
    langTheirs = l;
    notifyListeners();
    unawaited(_mt.preload(langMine, langTheirs));
  }

  void swapLangs() {
    final tmp = langMine;
    langMine = langTheirs;
    langTheirs = tmp;
    notifyListeners();
    unawaited(_stt.preload(langMine));
    unawaited(_mt.preload(langMine, langTheirs));
  }

  void setVolume(double v) {
    volume = v;
    notifyListeners();
    unawaited(_tts.setVolume(v / 100));
    unawaited(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_volumeKey, v);
      } catch (_) {
        // Non-fatal: the slider just won't remember its position.
      }
    }());
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

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _incomingSub?.cancel();
    _acksSub?.cancel();
    _partialSub?.cancel();
    _mt.dispose();
    super.dispose();
  }
}
