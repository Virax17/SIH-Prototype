import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _connection?.dispose();
    _connection = conn;
    _connStateSub = conn.stateStream.listen((s) {
      if (s == BtcConnectionState.disconnected) {
        _connection = null;
      }
      notifyListeners();
    });
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
    _server?.close();
    _connection?.dispose();
    super.dispose();
  }
}
