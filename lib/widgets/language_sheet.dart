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
            onTap: app.closeLang,
            child: Container(color: Colors.black.withValues(alpha: 0.72)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
            decoration: const BoxDecoration(
              color: Color(0xFF111614),
              border: Border(top: BorderSide(color: Color(0xFF2B3830), width: 1.5)),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 52, height: 5, decoration: BoxDecoration(color: const Color(0xFF33413A), borderRadius: BorderRadius.circular(3))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(child: Text('Speak', style: TextStyle(fontFamily: barlow, fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white))),
                    Material(
                      color: const Color(0xFF1C2620),
                      borderRadius: BorderRadius.circular(11),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(11),
                        onTap: app.swapLang,
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFF33413A), width: 1.5)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.swap_horiz, color: AppColors.amber, size: 20),
                              SizedBox(width: 8),
                              Text('Swap', style: TextStyle(fontFamily: barlow, fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.amber)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                for (final l in kLangs) ...[
                  _LangCard(l: l, active: l.code == app.dst, onTap: () => app.pickLang(l.code)),
                  const SizedBox(height: 9),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LangCard extends StatelessWidget {
  final LangOption l;
  final bool active;
  final VoidCallback onTap;
  const _LangCard({required this.l, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = active ? AppColors.amberSelectedBg : const Color(0xFF151B17);
    final border = active ? AppColors.amberSelectedBorder : const Color(0xFF2B3830);
    final glyphColor = active ? AppColors.amberGlyph : const Color(0xFFCFD9D3);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 82),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 2)),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(color: const Color(0xFF0D1210), borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text(l.glyph, style: TextStyle(fontFamily: l.glyphFontFamily ?? barlow, fontWeight: FontWeight.w700, fontSize: 24, color: glyphColor)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.native, style: TextStyle(fontFamily: l.glyphFontFamily ?? barlow, fontWeight: FontWeight.w700, fontSize: 24, height: 1.05, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('${l.latin.toUpperCase()} · OFFLINE', style: const TextStyle(fontFamily: mono, fontWeight: FontWeight.w500, fontSize: 11.5, letterSpacing: 1.0, color: Color(0xFF7D8A83))),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: const Color(0xFF1C2620), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF33413A), width: 1.5)),
                child: const Icon(Icons.play_arrow, color: Color(0xFFCFD9D3), size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
