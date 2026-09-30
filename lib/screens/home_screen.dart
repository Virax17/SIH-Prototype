import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services/bluetooth_manager.dart';
import '../theme.dart';
import 'conversation_screen.dart';
import 'devices_screen.dart';
import 'network_screen.dart';

/// Matches the reference design's "Talk home": mesh status card, a "Nearby"
/// device list (real Bluetooth history/paired devices — iTantra supports one
/// direct connection at a time, so there's no fake multi-device reach data),
/// and links to the device list ("Nearby devices") and the honest 2-node
/// connection graph ("Your network"). Tapping a device opens Conversation.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final bt = context.watch<BluetoothManager>();
    final connected = bt.connectedDevice;

    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: Text('Talk', style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w800, fontSize: 30, color: AppColors.textPrimary))),
                _EmergencyPill(onTap: app.triggerEmergency),
              ],
            ),
            const SizedBox(height: 14),
            _MeshStatusCard(connectedCount: connected != null ? 1 : 0),
            if (app.emergencyMode) ...[
              const SizedBox(height: 10),
              _EmergencyModeBanner(),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nearby', style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textPrimary)),
                InkWell(
                  onTap: connected != null ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConversationScreen())) : null,
                  child: Text('Tap to talk', style: TextStyle(fontFamily: appFont, fontSize: 13, fontWeight: FontWeight.w600, color: connected != null ? AppColors.accent : AppColors.textSecondary(0.3))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (connected != null)
              _NearbyRow(
                name: connected.displayName,
                status: 'Connected',
                statusColor: AppColors.success,
                icon: Icons.phone_android,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConversationScreen())),
              )
            else
              ...bt.history.take(3).map(
                    (h) => _NearbyRow(
                      name: h.name,
                      status: 'Tap to connect',
                      statusColor: AppColors.textSecondary(0.5),
                      icon: Icons.history,
                      onTap: () async {
                        await bt.connectTo(h.address, knownName: h.name);
                        if (context.mounted && bt.isConnected) {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConversationScreen()));
                        }
                      },
                    ),
                  ),
            if (connected == null && bt.history.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border(0.08))),
                child: Text(
                  'No devices yet — pair one to start talking.',
                  style: TextStyle(fontFamily: appFont, fontSize: 13, color: AppColors.textSecondary(0.5)),
                ),
              ),
            const SizedBox(height: 4),
            _LinkRow(
              icon: Icons.phone_android,
              title: 'Nearby devices',
              subtitle: bt.history.isEmpty ? 'Find and pair a device' : '${bt.history.length} known device${bt.history.length == 1 ? '' : 's'}',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DevicesScreen())),
            ),
            const SizedBox(height: 10),
            _LinkRow(
              icon: Icons.hub_outlined,
              title: 'Your network',
              subtitle: 'See how messages travel',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NetworkScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyPill extends StatelessWidget {
  final VoidCallback onTap;
  const _EmergencyPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), border: Border.all(color: AppColors.danger.withValues(alpha: 0.4))),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 15, color: AppColors.danger),
              SizedBox(width: 6),
              Text('Emergency', style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.danger)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeshStatusCard extends StatelessWidget {
  final int connectedCount;
  const _MeshStatusCard({required this.connectedCount});

  @override
  Widget build(BuildContext context) {
    final active = connectedCount > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: active ? const Color(0x1A2F9E5C) : AppColors.card, borderRadius: BorderRadius.circular(16), border: active ? null : Border.all(color: AppColors.border(0.08))),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.hub, size: 20, color: active ? AppColors.success : AppColors.textSecondary(0.4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: active ? AppColors.success : AppColors.textSecondary(0.35))),
                    const SizedBox(width: 6),
                    Text(active ? 'Mesh connected' : 'Mesh idle', style: TextStyle(fontFamily: appFont, fontSize: 12, fontWeight: FontWeight.w600, color: active ? AppColors.success : AppColors.textSecondary(0.5))),
                  ],
                ),
                const SizedBox(height: 2),
                Text(active ? 'Offline mesh active' : 'No device connected', style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary)),
                Text(
                  active ? '$connectedCount device connected' : 'Connect a device to start talking',
                  style: TextStyle(fontFamily: appFont, fontSize: 12.5, color: AppColors.textSecondary(0.55)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyModeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.shield, size: 16, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Emergency Mode active — communication prioritized',
              style: TextStyle(fontFamily: appFont, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyRow extends StatelessWidget {
  final String name;
  final String status;
  final Color statusColor;
  final IconData icon;
  final VoidCallback onTap;
  const _NearbyRow({required this.name, required this.status, required this.statusColor, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border(0.08))),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
              child: Center(child: Text(name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?', style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.accent))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.textPrimary)),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
                      const SizedBox(width: 5),
                      Text(status, style: TextStyle(fontFamily: appFont, fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                    ],
                  ),
                ],
              ),
            ),
            Material(
              color: AppColors.accent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: const Padding(padding: EdgeInsets.all(11), child: Icon(Icons.mic, size: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _LinkRow({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border(0.08))),
          child: Row(
            children: [
              Container(width: 36, height: 36, decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle), child: Icon(icon, size: 16, color: AppColors.accent)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                    Text(subtitle, style: TextStyle(fontFamily: appFont, fontSize: 12, color: AppColors.textSecondary(0.5))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary(0.35)),
            ],
          ),
        ),
      ),
    );
  }
}
