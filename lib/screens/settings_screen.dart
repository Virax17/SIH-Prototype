import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tk = app.themeMode == AppThemeMode.dark ? ThemeTokens.dark : ThemeTokens.light;
    final volLabel = app.vol >= 10 ? 'MAX' : '${app.vol * 10}%';

    return Container(
      color: tk.bg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _BackButton(tk: tk, onTap: app.goHome),
                const SizedBox(width: 12),
                Text('Settings', style: TextStyle(fontFamily: barlow, fontWeight: FontWeight.w700, fontSize: 24, color: tk.text)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
              children: [
                _SectionLabel('Link', tk: tk),
                _SettingsRow(
                  tk: tk,
                  onTap: app.goPairing,
                  leading: const _SignalIconBadge(),
                  title: 'Paired device',
                  subtitle: kPairedDeviceName,
                  trailing: const Icon(Icons.arrow_forward, color: Color(0xFF6F7D76), size: 22),
                ),
                _SectionLabel('Language', tk: tk),
                _SettingsRow(
                  tk: tk,
                  onTap: app.openLang,
                  leading: _GlyphBadge(text: 'अ'),
                  title: 'Default pair',
                  subtitle: '${app.src} → ${app.dst}',
                  trailing: const Icon(Icons.arrow_forward, color: Color(0xFF6F7D76), size: 22),
                ),
                _SectionLabel('Audio', tk: tk),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111614),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFF232E28), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.volume_up_outlined, color: Color(0xFFCFD9D3), size: 26),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Playback volume', style: TextStyle(fontFamily: barlow, fontWeight: FontWeight.w600, fontSize: 18, color: tk.text))),
                          Text(volLabel, style: const TextStyle(fontFamily: mono, fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.amber)),
                        ],
                      ),
                      const SizedBox(height: 13),
                      SizedBox(
                        height: 34,
                        child: Row(
                          children: List.generate(10, (i) {
                            final lit = i < app.vol;
                            final color = lit ? (i >= 8 ? AppColors.red : AppColors.amber) : const Color(0xFF1E2723);
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                                child: Material(
                                  color: color,
                                  borderRadius: BorderRadius.circular(5),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(5),
                                    onTap: () => app.setVol(i + 1),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _ToggleRow(
                  tk: tk,
                  leadingBg: AppColors.redSoftBg,
                  leading: const Icon(Icons.warning_amber_rounded, color: AppColors.redGlyph, size: 24),
                  title: 'Emergency override',
                  subtitle: 'Priority plays at max volume',
                  value: app.alertOn,
                  onColor: AppColors.red,
                  onTap: app.toggleAlert,
                ),
                const SizedBox(height: 10),
                _ToggleRow(
                  tk: tk,
                  leadingBg: const Color(0xFF1C2620),
                  leading: const Icon(Icons.wb_sunny_outlined, color: Color(0xFFCFD9D3), size: 24),
                  title: 'Sunlight (light) theme',
                  subtitle: 'For bright outdoor readability',
                  value: app.themeMode == AppThemeMode.light,
                  onColor: const Color(0xFF2B3830),
                  onTap: app.toggleTheme,
                ),
                _SectionLabel('About', tk: tk),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: tk.panelBg,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: tk.panelBorder, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      _AboutRow(label: 'Version', value: '1.0.0 (build 41)', tk: tk),
                      const SizedBox(height: 7),
                      _AboutRow(label: 'Speech models', value: 'on-device · 214 MB', tk: tk),
                      const SizedBox(height: 7),
                      _AboutRow(label: 'Network', value: 'never required', valueColor: AppColors.green, tk: tk),
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
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final ThemeTokens tk;
  const _AboutRow({required this.label, required this.value, required this.tk, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontFamily: mono, fontSize: 12.5, height: 1.5, color: tk.textSec)),
        Text(value, style: TextStyle(fontFamily: mono, fontSize: 12.5, height: 1.5, color: valueColor ?? const Color(0xFFCFD9D3))),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final ThemeTokens tk;
  const _SectionLabel(this.text, {required this.tk});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Text(text.toUpperCase(), style: const TextStyle(fontFamily: mono, fontWeight: FontWeight.w500, fontSize: 10.5, letterSpacing: 1.3, color: Color(0xFF66736C))),
    );
  }
}

class _SignalIconBadge extends StatelessWidget {
  const _SignalIconBadge();
  @override
  Widget build(BuildContext context) {
    final heights = [7.0, 12.0, 17.0, 22.0];
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: const Color(0xFF1C2620), borderRadius: BorderRadius.circular(11)),
      child: Center(
        child: SizedBox(
          height: 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(4, (i) => Padding(
                  padding: const EdgeInsets.only(right: 2.5),
                  child: Container(width: 4, height: heights[i] * 0.9, decoration: BoxDecoration(color: i < 3 ? AppColors.green : const Color(0xFF2C3A32), borderRadius: BorderRadius.circular(1))),
                )),
          ),
        ),
      ),
    );
  }
}

class _GlyphBadge extends StatelessWidget {
  final String text;
  const _GlyphBadge({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: const Color(0xFF1C2620), borderRadius: BorderRadius.circular(11)),
      child: Center(child: Text(text, style: const TextStyle(fontFamily: 'NotoSansDevanagari', fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.amber))),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final ThemeTokens tk;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;
  const _SettingsRow({required this.tk, required this.onTap, required this.leading, required this.title, required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF111614),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFF232E28), width: 1.5)),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: TextStyle(fontFamily: barlow, fontWeight: FontWeight.w600, fontSize: 18, color: tk.text)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(fontFamily: mono, fontSize: 12, color: tk.textSec)),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final ThemeTokens tk;
  final Color leadingBg;
  final Widget leading;
  final String title;
  final String subtitle;
  final bool value;
  final Color onColor;
  final VoidCallback onTap;
  const _ToggleRow({
    required this.tk,
    required this.leadingBg,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF111614),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFF232E28), width: 1.5)),
          child: Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: leadingBg, borderRadius: BorderRadius.circular(11)), child: Center(child: leading)),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: TextStyle(fontFamily: barlow, fontWeight: FontWeight.w600, fontSize: 18, color: tk.text)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(fontFamily: mono, fontSize: 12, height: 1.25, color: tk.textSec)),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 62,
                height: 36,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: value ? onColor : const Color(0xFF2B3830), borderRadius: BorderRadius.circular(18)),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 150),
                  alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(width: 30, height: 30, decoration: const BoxDecoration(color: Color(0xFF0A0C0B), shape: BoxShape.circle)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final ThemeTokens tk;
  final VoidCallback onTap;
  const _BackButton({required this.tk, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tk.cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: tk.cardBorder, width: 1.5)),
          child: const Icon(Icons.arrow_back, color: Color(0xFFCFD9D3), size: 26),
        ),
      ),
    );
  }
}
