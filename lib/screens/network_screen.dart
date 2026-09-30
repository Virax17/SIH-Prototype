import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/bluetooth_manager.dart';
import '../theme.dart';

/// Honest version of the mockup's "Your network" multi-hop graph: iTantra
/// has exactly one direct Bluetooth connection, so this shows You↔peer only
/// — no relay nodes, no fabricated hop counts.
class NetworkScreen extends StatelessWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bt = context.watch<BluetoothManager>();
    final connected = bt.connectedDevice;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Your network', style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.textPrimary)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Node(label: 'YOU', filled: true),
                  Container(
                    width: 56,
                    height: 2,
                    color: connected != null ? AppColors.success : AppColors.border(0.15),
                  ),
                  _Node(
                    label: (connected != null && connected.displayName.isNotEmpty) ? connected.displayName.substring(0, 1).toUpperCase() : '?',
                    filled: connected != null,
                    connected: connected != null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              connected != null ? connected.displayName : 'No device connected',
              style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border(0.08))),
              child: Row(
                children: [
                  Text(
                    connected != null ? '1' : '0',
                    style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w800, fontSize: 26, color: AppColors.accent),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'device connected\niTantra connects directly, phone-to-phone — no relay through other devices yet.',
                      style: TextStyle(fontFamily: appFont, fontSize: 12.5, height: 1.3, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Node extends StatelessWidget {
  final String label;
  final bool filled;
  final bool connected;
  const _Node({required this.label, required this.filled, this.connected = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: filled ? AppColors.accent : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: connected ? AppColors.success : AppColors.accent, width: 2),
          ),
          child: Center(
            child: Text(label, style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w800, fontSize: 15, color: filled ? Colors.white : AppColors.accent)),
          ),
        ),
      ],
    );
  }
}
