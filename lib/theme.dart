import 'package:flutter/material.dart';

/// Colors approximated from the design's OKLCH values into sRGB hex.
class AppColors {
  // Accent — "system voice" amber
  static const amber = Color(0xFFCC9B47);
  static const amberBright = Color(0xFFDBB268);
  static const amberBorder = Color(0xFF8C723F);
  static const amberSoftBg = Color(0xFF3A3226);
  static const amberSoftBorder = Color(0xFF5C4C2E);
  static const amberGlyph = Color(0xFFE0BD7E);
  static const amberSelectedBg = Color(0xFF362F24);
  static const amberSelectedBorder = Color(0xFF9C7F4E);

  // Link healthy — green
  static const green = Color(0xFF4CAF7A);

  // Recording / priority — red
  static const red = Color(0xFFDD4B32);
  static const redDeep = Color(0xFFC03E28);
  static const redSoftBg = Color(0xFF3A241E);
  static const redSoftBorder = Color(0xFFC03E28);
  static const redHoverBg = Color(0xFF472C22);
  static const redGlyph = Color(0xFFE07A54);
  static const redText = Color(0xFFE79471);
  static const sirenA = Color(0xFFC03E28);
  static const sirenB = Color(0xFFD6672E);
}

class ThemeTokens {
  final Color bg;
  final Color text;
  final Color textSec;
  final Color cardBg;
  final Color cardBorder;
  final Color panelBg;
  final Color panelBorder;

  const ThemeTokens({
    required this.bg,
    required this.text,
    required this.textSec,
    required this.cardBg,
    required this.cardBorder,
    required this.panelBg,
    required this.panelBorder,
  });

  static const dark = ThemeTokens(
    bg: Color(0xFF0A0C0B),
    text: Color(0xFFEDF2EE),
    textSec: Color(0xFF7D8A83),
    cardBg: Color(0xFF141916),
    cardBorder: Color(0xFF27332C),
    panelBg: Color(0xFF0E1210),
    panelBorder: Color(0xFF1E2723),
  );

  static const light = ThemeTokens(
    bg: Color(0xFFF4F2EC),
    text: Color(0xFF12160F),
    textSec: Color(0xFF5C6459),
    cardBg: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFDCDAC9),
    panelBg: Color(0xFFFBFAF5),
    panelBorder: Color(0xFFE2E0D1),
  );
}

const barlow = 'Barlow';
const mono = 'IBMPlexMono';
