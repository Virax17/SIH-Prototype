import 'package:flutter/material.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:provider/provider.dart';

import '../services/bluetooth_manager.dart';
import '../theme.dart';

/// Rough heuristic to hide obvious non-phone accessories (earbuds, speakers,
/// wearables, PCs) from the "Find new" list by name. The Bluetooth Classic
/// plugin this app uses doesn't expose the device's Bluetooth "major device
/// class", so this is a best-effort name match, not a reliable device-type
/// check — devices with ambiguous/serial-number names are left visible
/// rather than risk hiding a real phone.
bool looksLikeAccessory(String name) {
  final n = name.toLowerCase();
  const keywords = [
    'buds', 'airdopes', 'earbud', 'earphone', 'headphone', 'headset', 'airpod',
    'speaker', 'soundbar', 'tws', 'neckband',
    'watch', 'band', 'fitband', 'ring', 'tag', 'tracker',
    'mouse', 'keyboard', 'printer', 'laptop', 'macbook', 'desktop', 'pc-',
    'tv', 'glass',
    // Common accessory brand/model lines that don't otherwise contain a
    // generic keyword above (e.g. "boAt Rockerz", "Sony WH-CH520").
    'rockerz', 'boat', 'boult', 'ptron', 'zebronics', 'ubon', 'ambrane',
    'soundcore', 'liberty', 'jbl', 'wh-ch', 'wh-1000', 'wf-', 'wi-c',
  ];
  return keywords.any(n.contains);
}

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final TabController _tabs;
  bool _phonesOnly = true;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _spin.dispose();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.watch<BluetoothManager>();

    final needsPermission = bt.permissionStatus != BtcPermissionStatus.granted && bt.permissionStatus != BtcPermissionStatus.notRequired;
    final adapterOff = bt.adapterState == BtcAdapterState.off;

    final byAddress = <String, BtcDevice>{};
    for (final d in bt.discoveredDevices) {
      byAddress[d.address] = d;
    }
    for (final d in bt.pairedDevices) {
      byAddress[d.address] = byAddress.containsKey(d.address) ? d.mergedWith(byAddress[d.address]!) : d;
    }
    var findNewList = byAddress.values.toList()..sort((a, b) => a.displayName.compareTo(b.displayName));
    if (_phonesOnly) {
      findNewList = findNewList.where((d) => !looksLikeAccessory(d.displayName)).toList();
    }

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Devices', style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.textPrimary)),
                      Text('Bluetooth · works with no internet', style: TextStyle(fontFamily: appFont, fontSize: 12, color: Color(0x8817181A))),
                    ],
                  ),
                ),
                Material(
                  color: AppColors.accentSoft,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: needsPermission || adapterOff ? null : () => bt.scan(),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: bt.scanning
                            ? RotationTransition(turns: _spin, child: const Icon(Icons.sync, color: AppColors.accent, size: 19))
                            : const Icon(Icons.sync, color: AppColors.accent, size: 19),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (needsPermission)
            _InfoBanner(text: 'Bluetooth permission is required to find and connect to devices.', actionLabel: 'Grant permission', onAction: () => bt.init())
          else if (adapterOff)
            const _InfoBanner(text: 'Bluetooth is turned off. Enable it in system settings to continue.'),
          if (bt.lastError != null) _InfoBanner(text: bt.lastError!, danger: true),
          TabBar(
            controller: _tabs,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary(0.5),
            indicatorColor: AppColors.accent,
            labelStyle: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 13.5),
            unselectedLabelStyle: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w500, fontSize: 13.5),
            tabs: const [Tab(text: 'Find new'), Tab(text: 'History')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _FindNewTab(
                  bt: bt,
                  list: findNewList,
                  scanning: bt.scanning,
                  phonesOnly: _phonesOnly,
                  onTogglePhonesOnly: () => setState(() => _phonesOnly = !_phonesOnly),
                ),
                _HistoryTab(bt: bt),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FindNewTab extends StatelessWidget {
  final BluetoothManager bt;
  final List<BtcDevice> list;
  final bool scanning;
  final bool phonesOnly;
  final VoidCallback onTogglePhonesOnly;
  const _FindNewTab({required this.bt, required this.list, required this.scanning, required this.phonesOnly, required this.onTogglePhonesOnly});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  scanning ? 'Scanning for nearby devices…' : 'Paired devices and anything found nearby.',
                  style: TextStyle(fontFamily: appFont, fontSize: 12, color: AppColors.textSecondary(0.5)),
                ),
              ),
              InkWell(
                onTap: onTogglePhonesOnly,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: phonesOnly ? AppColors.accentSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: phonesOnly ? AppColors.accent.withValues(alpha: 0.35) : AppColors.border(0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_alt, size: 13, color: phonesOnly ? AppColors.accent : AppColors.textSecondary(0.5)),
                      const SizedBox(width: 5),
                      Text('Phones only', style: TextStyle(fontFamily: appFont, fontSize: 11.5, fontWeight: FontWeight.w600, color: phonesOnly ? AppColors.accent : AppColors.textSecondary(0.55))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      phonesOnly
                          ? 'No phones found. Try tapping scan, or turn off "Phones only" to see every paired/nearby device.'
                          : 'No devices yet. Pair a device in system Bluetooth settings, or tap scan to find nearby devices.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: appFont, fontSize: 13, color: AppColors.textSecondary(0.45)),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [for (final d in list) _DeviceCard(d: d, bt: bt)],
                ),
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final BluetoothManager bt;
  const _HistoryTab({required this.bt});

  @override
  Widget build(BuildContext context) {
    if (bt.history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Devices you connect to will show up here for quick reconnecting.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: appFont, fontSize: 13, color: AppColors.textSecondary(0.45)),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [for (final h in bt.history) _HistoryCard(h: h, bt: bt)],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final KnownDevice h;
  final BluetoothManager bt;
  const _HistoryCard({required this.h, required this.bt});

  @override
  Widget build(BuildContext context) {
    final connected = bt.connectedAddress == h.address;
    final connecting = bt.connectingAddress == h.address;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: connected ? AppColors.accent : AppColors.border(0.08), width: connected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: connected ? AppColors.accent : AppColors.accentSoft, shape: BoxShape.circle),
              child: Center(child: Icon(Icons.history, size: 18, color: connected ? Colors.white : AppColors.accent)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(h.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w600, fontSize: 14.5, color: AppColors.textPrimary)),
                  Text(
                    connected ? 'Connected' : (connecting ? 'Connecting…' : 'Last connected ${_relativeTime(h.lastConnected)}'),
                    style: TextStyle(fontFamily: appFont, fontSize: 12, fontWeight: FontWeight.w500, color: connected ? AppColors.success : AppColors.textSecondary(0.5)),
                  ),
                ],
              ),
            ),
            if (connected)
              const Icon(Icons.check, color: AppColors.success, size: 20)
            else if (connecting)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent, backgroundColor: AppColors.accent.withValues(alpha: 0.25)),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(100),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: bt.connectingAddress != null ? null : () => bt.connectTo(h.address, knownName: h.name),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        child: Text('Connect', style: TextStyle(fontFamily: appFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => bt.removeFromHistory(h.address),
                    icon: Icon(Icons.close, size: 16, color: AppColors.textSecondary(0.4)),
                    tooltip: 'Remove',
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static String _relativeTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool danger;
  const _InfoBanner({required this.text, this.actionLabel, this.onAction, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: danger ? AppColors.dangerSoft : AppColors.accentSoft, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: TextStyle(fontFamily: appFont, fontSize: 12.5, fontWeight: FontWeight.w500, color: danger ? AppColors.danger : AppColors.accent)),
            if (actionLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: InkWell(
                  onTap: onAction,
                  child: Text(actionLabel!, style: const TextStyle(fontFamily: appFont, fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.accent)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final BtcDevice d;
  final BluetoothManager bt;
  const _DeviceCard({required this.d, required this.bt});

  @override
  Widget build(BuildContext context) {
    final connected = bt.connectedAddress == d.address;
    final connecting = bt.connectingAddress == d.address;
    final paired = d.bondState == BtcBondState.bonded;

    final statusLabel = connected ? 'Connected' : (connecting ? 'Connecting…' : (paired ? 'Paired' : 'New device'));
    final statusColor = connected ? AppColors.success : (connecting ? AppColors.accent : AppColors.textSecondary(0.55));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: connected ? AppColors.accent : AppColors.border(0.08), width: connected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: connected ? AppColors.accent : AppColors.accentSoft, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  d.displayName.isNotEmpty ? d.displayName.substring(0, 1).toUpperCase() : '?',
                  style: TextStyle(fontFamily: appFont, fontSize: 16, fontWeight: FontWeight.w700, color: connected ? Colors.white : AppColors.accent),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(d.displayName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w600, fontSize: 14.5, color: AppColors.textPrimary)),
                  Text(statusLabel, style: TextStyle(fontFamily: appFont, fontSize: 12, fontWeight: FontWeight.w500, color: statusColor)),
                ],
              ),
            ),
            if (connected)
              const Icon(Icons.check, color: AppColors.success, size: 20)
            else if (connecting)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent, backgroundColor: AppColors.accent.withValues(alpha: 0.25)),
              )
            else
              Material(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(100),
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: bt.connectingAddress != null ? null : () => paired ? bt.connectTo(d.address) : bt.pairAndConnect(d.address),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    child: Text(paired ? 'Connect' : 'Pair', style: const TextStyle(fontFamily: appFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
