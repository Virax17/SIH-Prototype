import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

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
                    onTap: app.startScan,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: app.scanning
                            ? RotationTransition(turns: _spin, child: const Icon(Icons.sync, color: AppColors.accent, size: 19))
                            : const Icon(Icons.sync, color: AppColors.accent, size: 19),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (app.scanning)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(12)),
                child: const Text('Scanning for nearby devices…', style: TextStyle(fontFamily: appFont, fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.accent)),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [for (final d in app.devices) _DeviceCard(d: d, app: app)],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final BtDevice d;
  final AppState app;
  const _DeviceCard({required this.d, required this.app});

  @override
  Widget build(BuildContext context) {
    final connected = d.status == DeviceStatus.connected;
    final outOfRange = d.status == DeviceStatus.outOfRange;
    final avatarBg = connected ? AppColors.accent : (outOfRange ? AppColors.neutralSoft : AppColors.accentSoft);
    final avatarColor = connected ? Colors.white : (outOfRange ? AppColors.textSecondary(0.35) : AppColors.accent);
    final statusLabel = switch (d.status) {
      DeviceStatus.connected => 'Connected',
      DeviceStatus.available => 'Available',
      DeviceStatus.outOfRange => 'Out of range',
      DeviceStatus.connecting => 'Connecting…',
    };
    final statusColor = switch (d.status) {
      DeviceStatus.connected => AppColors.success,
      DeviceStatus.available => AppColors.textSecondary(0.55),
      DeviceStatus.outOfRange => AppColors.textSecondary(0.35),
      DeviceStatus.connecting => AppColors.accent,
    };

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
              decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle),
              child: Center(child: Text(d.name.substring(0, 1), style: TextStyle(fontFamily: appFont, fontSize: 16, fontWeight: FontWeight.w700, color: avatarColor))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(d.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w600, fontSize: 14.5, color: AppColors.textPrimary)),
                  Text(statusLabel, style: TextStyle(fontFamily: appFont, fontSize: 12, fontWeight: FontWeight.w500, color: statusColor)),
                ],
              ),
            ),
            if (connected)
              const Icon(Icons.check, color: AppColors.success, size: 20)
            else if (d.status == DeviceStatus.available)
              Material(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(100),
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () => app.connectDevice(d.id),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    child: Text('Connect', style: TextStyle(fontFamily: appFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              )
            else if (outOfRange)
              Material(
                color: AppColors.neutralSoft,
                borderRadius: BorderRadius.circular(100),
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () => app.retryDevice(d.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    child: Text('Retry', style: TextStyle(fontFamily: appFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary(0.6))),
                  ),
                ),
              )
            else
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent, backgroundColor: AppColors.accent.withValues(alpha: 0.25)),
              ),
          ],
        ),
      ),
    );
  }
}
