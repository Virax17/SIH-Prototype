import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

/// A message received over the connection: the text and the language it's
/// actually written in — sent by the peer, not assumed from our own
/// language setting, so playback uses the right TTS voice even if the two
/// phones' language pairs aren't perfectly mirrored.
class IncomingMessage {
  final String text;
  final LangCode lang;
  const IncomingMessage({required this.text, required this.lang});
}

/// A device this app has successfully connected to before, remembered
/// locally so the user can reconnect without rescanning/re-pairing.
class KnownDevice {
  final String address;
  final String name;
  final DateTime lastConnected;

  const KnownDevice({required this.address, required this.name, required this.lastConnected});

  factory KnownDevice.fromJson(Map<String, dynamic> j) => KnownDevice(
        address: j['address'] as String,
        name: j['name'] as String,
        lastConnected: DateTime.parse(j['lastConnected'] as String),
      );

  Map<String, dynamic> toJson() => {'address': address, 'name': name, 'lastConnected': lastConnected.toIso8601String()};
}

const _historyKey = 'itantra.bt.history';

/// Wraps flutter_classic_bluetooth with the app's connection state:
/// permissions, adapter status, paired/discovered devices, connection
/// history, and a single active RFCOMM link (either side may initiate —
/// this device always runs a background server so an incoming connection
/// is accepted automatically).
class BluetoothManager extends ChangeNotifier {
  static const _serviceName = 'iTantra';

  final _bt = FlutterClassicBluetooth();

  BtcPermissionStatus permissionStatus = BtcPermissionStatus.denied;
  BtcAdapterState adapterState = BtcAdapterState.unknown;

  List<BtcDevice> pairedDevices = [];
  List<BtcDevice> discoveredDevices = [];
  bool scanning = false;

  List<KnownDevice> history = [];

  BtcConnection? _connection;
  String? connectingAddress;
  String? lastError;

  BtcServerSocket? _server;
  StreamSubscription<BtcAdapterState>? _adapterSub;
  StreamSubscription<BtcConnection>? _serverSub;
  StreamSubscription<BtcConnectionState>? _connStateSub;
  StreamSubscription<String>? _incomingLinesSub;

  /// Messages received over the active connection — one recognized/
  /// translated utterance per event, tagged with the language it's actually
  /// written in (see [sendText]).
  final _incomingTextController = StreamController<IncomingMessage>.broadcast();
  Stream<IncomingMessage> get incomingText => _incomingTextController.stream;

  /// Fires the id of a message once the peer's [_incomingAcksController]
  /// echo confirms it was actually received (not just written to the radio).
  final _incomingAcksController = StreamController<int>.broadcast();
  Stream<int> get messageAcked => _incomingAcksController.stream;

  int _nextMessageId = 1;

  /// Sends [text] (already translated into [lang]) as a message to the
  /// connected device and returns an id that later appears on
  /// [messageAcked] once the peer confirms receipt. Returns null (silently)
  /// if nothing is connected, mirroring how a dropped voice packet would
  /// just not arrive rather than crashing the sender.
  Future<int?> sendText(String text, LangCode lang) async {
    // Collapse embedded newlines — the wire protocol is one message per
    // line, and multi-line input (e.g. the Broadcast compose box) would
    // otherwise split into unparseable fragments on the receiving end.
    final trimmed = text.trim().replaceAll(RegExp(r'\s*[\r\n]+\s*'), ' ');
    if (trimmed.isEmpty) return null;
    final conn = _connection;
    if (conn == null || !conn.isConnected) return null;
    final id = _nextMessageId++;
    try {
      await conn.output.writeLine('MSG $id ${lang.name} $trimmed', newline: '\n');
      return id;
    } catch (e) {
      lastError = '$e';
      notifyListeners();
      return null;
    }
  }

  Future<void> _handleIncomingLine(String line) async {
    if (line.startsWith('MSG ')) {
      final rest = line.substring(4);
      final sep1 = rest.indexOf(' ');
      if (sep1 < 0) return;
      final id = int.tryParse(rest.substring(0, sep1));
      if (id == null) return;
      final afterId = rest.substring(sep1 + 1);
      final sep2 = afterId.indexOf(' ');
      if (sep2 < 0) return;
      final langToken = afterId.substring(0, sep2);
      LangCode? lang;
      for (final l in LangCode.values) {
        if (l.name == langToken) {
          lang = l;
          break;
        }
      }
      if (lang == null) return;
      final text = afterId.substring(sep2 + 1);
      if (text.isNotEmpty) _incomingTextController.add(IncomingMessage(text: text, lang: lang));
      final conn = _connection;
      if (conn != null && conn.isConnected) {
        try {
          await conn.output.writeLine('ACK $id', newline: '\n');
        } catch (_) {
          // Non-fatal: the sender just won't see a "Delivered" tick.
        }
      }
    } else if (line.startsWith('ACK ')) {
      final id = int.tryParse(line.substring(4));
      if (id != null) _incomingAcksController.add(id);
    }
  }

  bool get isConnected => _connection?.isConnected ?? false;
  String? get connectedAddress => isConnected ? _connection!.address : null;

  BtcDevice? get connectedDevice {
    final addr = connectedAddress;
    if (addr == null) return null;
    for (final d in [...pairedDevices, ...discoveredDevices]) {
      if (d.address == addr) return d;
    }
    for (final h in history) {
      if (h.address == addr) return BtcDevice(address: addr, name: h.name);
    }
    return BtcDevice(address: addr);
  }

  Future<void> init() async {
    await _loadHistory();

    permissionStatus = await _bt.checkPermissions();
    if (permissionStatus == BtcPermissionStatus.denied) {
      permissionStatus = await _bt.requestPermissions();
    }
    notifyListeners();

    final ok = permissionStatus == BtcPermissionStatus.granted || permissionStatus == BtcPermissionStatus.notRequired;
    if (!ok) return;

    if (!await _bt.isEnabled()) {
      await _bt.enableBluetooth();
    }
    adapterState = await _bt.adapterState.first.catchError((_) => BtcAdapterState.unknown);
    _adapterSub = _bt.adapterState.listen((s) {
      adapterState = s;
      notifyListeners();
    });

    await refreshPairedDevices();
    await _startServer();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_historyKey) ?? [];
      history = raw.map((s) => KnownDevice.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.lastConnected.compareTo(a.lastConnected));
      notifyListeners();
    } catch (_) {
      history = [];
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_historyKey, history.map((h) => jsonEncode(h.toJson())).toList());
    } catch (_) {
      // Non-fatal: history just won't persist across restarts this time.
    }
  }

  Future<void> _rememberConnected(String address, String name) async {
    history = [
      KnownDevice(address: address, name: name, lastConnected: DateTime.now()),
      ...history.where((h) => h.address != address),
    ];
    notifyListeners();
    await _saveHistory();
  }

  Future<void> removeFromHistory(String address) async {
    history = history.where((h) => h.address != address).toList();
    notifyListeners();
    await _saveHistory();
  }

  Future<void> refreshPairedDevices() async {
    try {
      pairedDevices = await _bt.getPairedDevices();
      notifyListeners();
    } catch (e) {
      lastError = '$e';
      notifyListeners();
    }
  }

  Future<void> _startServer() async {
    try {
      _server = await _bt.startServer(serviceName: _serviceName);
      _serverSub = _server!.connections.listen(_adoptConnection);
    } catch (e) {
      lastError = '$e';
      notifyListeners();
    }
  }

  Future<void> scan({Duration timeout = const Duration(seconds: 8)}) async {
    if (scanning) return;
    scanning = true;
    discoveredDevices = [];
    notifyListeners();

    final sub = _bt.discoveryResults.listen((d) {
      final i = discoveredDevices.indexWhere((x) => x.address == d.address);
      if (i >= 0) {
        discoveredDevices[i] = discoveredDevices[i].mergedWith(d);
      } else {
        discoveredDevices = [...discoveredDevices, d];
      }
      notifyListeners();
    });

    try {
      await _bt.startDiscovery();
      await Future<void>.delayed(timeout);
    } catch (e) {
      lastError = '$e';
    } finally {
      try {
        await _bt.stopDiscovery();
      } catch (_) {}
      await sub.cancel();
      scanning = false;
      notifyListeners();
    }
  }

  Future<void> connectTo(String address, {String? knownName}) async {
    connectingAddress = address;
    lastError = null;
    notifyListeners();
    try {
      final conn = await _bt.connect(address: address, timeout: const Duration(seconds: 12));
      _adoptConnection(conn, fallbackName: knownName);
    } catch (e) {
      lastError = '$e';
    } finally {
      connectingAddress = null;
      notifyListeners();
    }
  }

  Future<void> pairAndConnect(String address) async {
    connectingAddress = address;
    lastError = null;
    notifyListeners();
    try {
      await _bt.bondDevice(address);
      await refreshPairedDevices();
      final conn = await _bt.connect(address: address, timeout: const Duration(seconds: 12));
      _adoptConnection(conn);
    } catch (e) {
      lastError = '$e';
    } finally {
      connectingAddress = null;
      notifyListeners();
    }
  }

  void _adoptConnection(BtcConnection conn, {String? fallbackName}) {
    _connStateSub?.cancel();
    _incomingLinesSub?.cancel();
    _connection?.dispose();
    _connection = conn;
    _connStateSub = conn.stateStream.listen((s) {
      if (s == BtcConnectionState.disconnected) {
        _connection = null;
      }
      notifyListeners();
    });
    _incomingLinesSub = conn.input.lines().listen(
      (line) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) unawaited(_handleIncomingLine(trimmed));
      },
      onError: (Object e) {
        lastError = '$e';
        notifyListeners();
      },
    );
    notifyListeners();

    final name = connectedDevice?.displayName ?? fallbackName ?? conn.address;
    unawaited(_rememberConnected(conn.address, name));
  }

  Future<void> disconnect() async {
    await _connection?.finish();
    _connection = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _adapterSub?.cancel();
    _serverSub?.cancel();
    _connStateSub?.cancel();
    _incomingLinesSub?.cancel();
    _incomingTextController.close();
    _incomingAcksController.close();
    _server?.close();
    _connection?.dispose();
    super.dispose();
  }
}
