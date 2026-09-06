import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

class AlertHistoryScreen extends StatelessWidget {
  const AlertHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Row(
                children: [
                  Material(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border(0.08))),
                        child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alert history', style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.textPrimary)),
                        Text('Kept permanently on this device', style: TextStyle(fontFamily: appFont, fontSize: 12, color: Color(0x8817181A))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: app.alertHistory.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No government alerts have been broadcast or received yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: appFont, fontSize: 13, color: AppColors.textSecondary(0.45)),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      children: [for (final a in app.alertHistory) _AlertCard(a: a)],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final EmergencyAlertRecord a;
  const _AlertCard({required this.a});

  @override
  Widget build(BuildContext context) {
    final sent = a.dir == MsgDir.sent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border(0.08))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, size: 14, color: AppColors.danger),
                const SizedBox(width: 6),
                Text(
                  sent ? 'BROADCAST BY YOU' : 'RECEIVED',
                  style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 10.5, letterSpacing: 0.6, color: AppColors.danger),
                ),
                const Spacer(),
                Text(_formatTimestamp(a.timestamp), style: TextStyle(fontFamily: appFont, fontSize: 11, color: AppColors.textSecondary(0.45))),
              ],
            ),
            const SizedBox(height: 8),
            Text(a.native, style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w600, fontSize: 15, height: 1.3, color: AppColors.textPrimary)),
            if (a.latin != a.native) ...[
              const SizedBox(height: 3),
              Text(a.latin, style: TextStyle(fontFamily: appFont, fontSize: 12.5, fontStyle: FontStyle.italic, color: AppColors.textSecondary(0.5))),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatTimestamp(DateTime t) {
    final now = DateTime.now();
    final sameDay = t.year == now.year && t.month == now.month && t.day == now.day;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    if (sameDay) return '$hh:$mm';
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year} $hh:$mm';
  }
}
