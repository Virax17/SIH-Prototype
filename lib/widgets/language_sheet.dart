import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

class LanguageSheet extends StatelessWidget {
  const LanguageSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: app.closeLangSheet,
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border(0.15), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Language pair', style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.textPrimary)),
                ),
                const SizedBox(height: 16),
                _sectionLabel('I speak'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final l in LangCode.values) ...[
                      Expanded(child: _LangPill(l: l, active: app.langMine == l, onTap: () => app.selectMine(l))),
                      if (l != LangCode.values.last) const SizedBox(width: 8),
                    ],
                  ],
                ),
                Transform.translate(
                  offset: const Offset(0, -8),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 8),
                    child: Center(
                      child: Material(
                        color: AppColors.neutralSoft,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: app.swapLangs,
                          child: const Padding(
                            padding: EdgeInsets.all(11),
                            child: Icon(Icons.swap_vert, size: 18, color: AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _sectionLabel('I hear'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final l in LangCode.values) ...[
                      Expanded(child: _LangPill(l: l, active: app.langTheirs == l, onTap: () => app.selectTheirs(l))),
                      if (l != LangCode.values.last) const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 22),
                Material(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(100),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: app.closeLangSheet,
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 56),
                      alignment: Alignment.center,
                      child: const Text('Done', style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text.toUpperCase(), style: TextStyle(fontFamily: appFont, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 0.6, color: AppColors.textSecondary(0.5))),
      );
}

class _LangPill extends StatelessWidget {
  final LangCode l;
  final bool active;
  final VoidCallback onTap;
  const _LangPill({required this.l, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.accentSoft : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? AppColors.accent : AppColors.border(0.15), width: 2),
          ),
          child: Text(
            l.nativeName,
            style: TextStyle(fontFamily: l.glyphFontFamily ?? appFont, fontSize: 13.5, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
