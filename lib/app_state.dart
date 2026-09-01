import 'dart:async';
import 'package:flutter/material.dart';
import 'models.dart';

enum Screen { home, pairing, settings, emergency }

enum Mode { idle, rec, incoming }

enum Sheet { none, lang }

enum AppThemeMode { dark, light }

const _phrases = [
  ['Send water to sector four', 'सेक्टर चार में पानी भेजो'],
  ['Two people trapped near the bridge', 'पुल के पास दो लोग फंसे हैं'],
  ['Road is clear, move the truck', 'रास्ता साफ है, ट्रक भेजो'],
];

const _replies = [
  {'text': 'Water is on the way, ten minutes.', 'tag': 'RECEIVED · HI → EN'},
  {'text': 'Team Bravo copies. Holding position.', 'tag': 'RECEIVED · TA → EN'},
];

const kPairedDeviceName = 'ITX-7742 · Bravo';

/// Mirrors the state machine from the Claude Design prototype (iTantra.dc.html),
/// with the same simulated STT/reply behavior. Real STT/TTS/Bluetooth wiring
/// replaces the simulation methods in a later pass.
class AppState extends ChangeNotifier {
  Screen screen = Screen.home;
  Mode mode = Mode.idle;
  Sheet sheet = Sheet.none;
  bool scanning = true;
  String src = 'EN';
  String dst = 'HI';
  int vol = 8;
  bool alertOn = true;
  AppThemeMode themeMode = AppThemeMode.dark;
  bool confirming = false;
  int countdown = 3;
  String partial = '';
  int phraseIdx = 0;
  int replyIdx = 0;
  final List<DateTime> _tapTimes = [];

  List<Message> messages = [
    Message(id: 1, dir: MsgDir.recv, tag: 'RECEIVED · HI → EN', text: 'Are you at the relief camp?'),
    Message(id: 2, dir: MsgDir.sent, tag: 'SENT · EN → HI', text: 'Yes, north gate. Bring blankets.'),
  ];

  Timer? _partialTimer;
  Timer? _holdTimer;
  Timer? _replyTimer;
  Timer? _countdownTimer;

  bool get isRec => mode == Mode.rec;
  bool get isIncoming => mode == Mode.incoming;
  bool get isIdle => mode == Mode.idle;

  void registerGlobalTap() {
    final now = DateTime.now();
    _tapTimes.removeWhere((t) => now.difference(t).inMilliseconds >= 600);
    _tapTimes.add(now);
    if (_tapTimes.length >= 3) {
      _tapTimes.clear();
      beginConfirm();
    }
  }

  void _cancelTimers() {
    _partialTimer?.cancel();
    _holdTimer?.cancel();
    _replyTimer?.cancel();
    _countdownTimer?.cancel();
  }

  void setScene(Screen s, {Mode mode = Mode.idle, Sheet sheet = Sheet.none}) {
    _cancelTimers();
    screen = s;
    this.mode = mode;
    this.sheet = sheet;
    partial = '';
    confirming = false;
    notifyListeners();
  }

  void beginConfirm() {
    _partialTimer?.cancel();
    _holdTimer?.cancel();
    mode = Mode.idle;
    confirming = true;
    countdown = 3;
    notifyListeners();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      countdown -= 1;
      if (countdown <= 0) {
        t.cancel();
        confirming = false;
        screen = Screen.emergency;
      }
      notifyListeners();
    });
  }

  void cancelConfirm() {
    _countdownTimer?.cancel();
    confirming = false;
    notifyListeners();
  }

  void startRec() {
    if (mode == Mode.rec) return;
    final words = _phrases[phraseIdx % _phrases.length][0].split(' ');
    var i = 0;
    mode = Mode.rec;
    partial = '';
    notifyListeners();
    _partialTimer?.cancel();
    _partialTimer = Timer.periodic(const Duration(milliseconds: 240), (t) {
      i += 1;
      partial = words.sublist(0, i.clamp(0, words.length)).join(' ');
      notifyListeners();
      if (i >= words.length) t.cancel();
    });
    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(milliseconds: 3000), beginConfirm);
  }

  void stopRec() {
    _holdTimer?.cancel();
    if (mode != Mode.rec) return;
    _partialTimer?.cancel();
    final p = _phrases[phraseIdx % _phrases.length];
    final said = partial.split(' ').length > 2 ? partial : p[0];
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch,
      dir: MsgDir.sent,
      tag: 'SENT · $src → $dst',
      text: said,
    );
    messages = [...messages, message];
    if (messages.length > 4) messages = messages.sublist(messages.length - 4);
    mode = Mode.idle;
    partial = '';
    phraseIdx += 1;
    notifyListeners();
    _replyTimer?.cancel();
    _replyTimer = Timer(const Duration(milliseconds: 1500), incoming);
  }

  void incoming() {
    final r = _replies[replyIdx % _replies.length];
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch + 1,
      dir: MsgDir.recv,
      tag: r['tag']!,
      text: r['text']!,
    );
    messages = [...messages, message];
    if (messages.length > 4) messages = messages.sublist(messages.length - 4);
    mode = Mode.incoming;
    replyIdx += 1;
    notifyListeners();
    _replyTimer?.cancel();
    _replyTimer = Timer(const Duration(milliseconds: 3800), () {
      mode = Mode.idle;
      notifyListeners();
    });
  }

  void replay() {
    mode = Mode.incoming;
    notifyListeners();
    _replyTimer?.cancel();
    _replyTimer = Timer(const Duration(milliseconds: 3200), () {
      mode = Mode.idle;
      notifyListeners();
    });
  }

  void toggleScan() {
    scanning = !scanning;
    notifyListeners();
  }

  void retryScan() {
    scanning = true;
    notifyListeners();
  }

  void connectTo() {
    setScene(Screen.home);
  }

  void swapLang() {
    final tmp = src;
    src = dst;
    dst = tmp;
    notifyListeners();
  }

  void openLang() {
    sheet = Sheet.lang;
    notifyListeners();
  }

  void closeLang() {
    sheet = Sheet.none;
    notifyListeners();
  }

  void pickLang(String code) {
    dst = code;
    sheet = Sheet.none;
    notifyListeners();
  }

  void toggleAlert() {
    alertOn = !alertOn;
    notifyListeners();
  }

  void toggleTheme() {
    themeMode = themeMode == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    notifyListeners();
  }

  void setVol(int v) {
    vol = v;
    notifyListeners();
  }

  void goHome() => setScene(Screen.home);
  void goPairing() => setScene(Screen.pairing);
  void goSettings() => setScene(Screen.settings);
  void ackEmergency() => setScene(Screen.home);

  final devices = const [
    DeviceInfo(name: kPairedDeviceName, status: 'connected · 4 bars', state: DeviceLinkState.connected, bars: 4),
    DeviceInfo(name: 'ITX-3190 · Medical', status: 'available', state: DeviceLinkState.available, bars: 3),
    DeviceInfo(name: 'ITX-0058 · Base camp', status: 'out of range — last seen 4 min', state: DeviceLinkState.failed, bars: 1),
    DeviceInfo(name: 'Unknown device', status: 'available', state: DeviceLinkState.available, bars: 2),
  ];

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}
