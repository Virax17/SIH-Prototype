import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../services/bluetooth_manager.dart';
import '../theme.dart';
import 'alert_history_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final connected = context.watch<BluetoothManager>().connectedDevice;

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Settings', style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.textPrimary)),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _SettingsRow(
                  onTap: () => app.setTab(AppTab.devices),
                  iconBg: AppColors.accentSoft,
                  icon: const Icon(Icons.bluetooth, color: AppColors.accent, size: 18),
                  title: 'Paired device',
                  subtitle: connected?.displayName ?? 'No device paired',
                  trailing: true,
                ),
                const SizedBox(height: 8),
                _SettingsRow(
                  onTap: app.openLangSheet,
                  iconBg: AppColors.accentSoft,
                  icon: const Icon(Icons.swap_horiz, color: AppColors.accent, size: 18),
                  title: 'Default language pair',
                  subtitle: '${app.langMine.latinName} → ${app.langTheirs.latinName}',
                  trailing: true,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border(0.08))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
                        child: const Icon(Icons.volume_up, color: AppColors.accent, size: 17),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Playback volume', style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                              ),
                              child: Slider(
                                value: app.volume,
                                min: 0,
                                max: 100,
                                activeColor: AppColors.accent,
                                inactiveColor: AppColors.border(0.12),
                                onChanged: app.setVolume,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _ToggleRow(
                  onTap: app.toggleEmergencyEnabled,
                  iconBg: AppColors.dangerSoft,
                  icon: const Icon(Icons.campaign_outlined, color: AppColors.danger, size: 17),
                  title: 'Emergency alerts',
                  subtitle: 'Full-screen, max volume, non-dismissible',
                  value: app.emergencyEnabled,
                ),
                const SizedBox(height: 8),
                _SettingsRow(
                  onTap: app.toggleScriptMode,
                  iconBg: AppColors.neutralSoft,
                  icon: Text('Aa', style: TextStyle(fontFamily: appFont, fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary(0.55))),
                  title: 'Transcript text',
                  subtitle: 'Voice is primary — text is shown as: ${_scriptModeLabel(app.scriptMode)}',
                  trailing: true,
                ),
                const SizedBox(height: 8),
                _SettingsRow(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlertHistoryScreen())),
                  iconBg: AppColors.dangerSoft,
                  icon: const Icon(Icons.account_balance, color: AppColors.danger, size: 17),
                  title: 'Alert history',
                  subtitle: app.alertHistory.isEmpty ? 'No alerts logged yet' : '${app.alertHistory.length} alert${app.alertHistory.length == 1 ? '' : 's'} logged · kept permanently',
                  trailing: true,
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 16, 14, 4),
                  child: Column(
                    children: [
                      Text('iTantra v1.0.0 · Build 2026.09', style: TextStyle(fontFamily: appFont, fontSize: 12, color: Color(0x6617181A))),
                      SizedBox(height: 2),
                      Text('Offline push-to-talk voice translator', style: TextStyle(fontFamily: appFont, fontSize: 11.5, color: Color(0x4D17181A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _scriptModeLabel(ScriptMode m) {
    switch (m) {
      case ScriptMode.both:
        return 'Both';
      case ScriptMode.native:
        return 'Native script';
      case ScriptMode.latin:
        return 'Latin script';
    }
  }
}

class _SettingsRow extends StatelessWidget {
  final VoidCallback onTap;
  final Color iconBg;
  final Widget icon;
  final String title;
  final String subtitle;
  final bool trailing;
  const _SettingsRow({required this.onTap, required this.iconBg, required this.icon, required this.title, required this.subtitle, this.trailing = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border(0.08))),
          child: Row(
            children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), child: Center(child: icon)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                    Text(subtitle, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: appFont, fontSize: 12.5, color: AppColors.textSecondary(0.5))),
                  ],
                ),
              ),
              if (trailing) Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary(0.35)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final VoidCallback onTap;
  final Color iconBg;
  final Widget icon;
  final String title;
  final String subtitle;
  final bool value;
  const _ToggleRow({required this.onTap, required this.iconBg, required this.icon, required this.title, required this.subtitle, required this.value});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border(0.08))),
          child: Row(
            children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), child: Center(child: icon)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontFamily: appFont, fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                    Text(subtitle, style: TextStyle(fontFamily: appFont, fontSize: 12.5, color: AppColors.textSecondary(0.5))),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 26,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: value ? AppColors.accent : AppColors.border(0.18), borderRadius: BorderRadius.circular(100)),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 150),
                  alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 3, offset: const Offset(0, 1))]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
