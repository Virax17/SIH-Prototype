import 'package:flutter/material.dart';

/// Light theme palette matching the new Claude Design handoff.
class AppColors {
  static const bg = Color(0xFFF1F0EC);
  static const surface = Color(0xFFFAFAF8);
  static const card = Color(0xFFFFFFFF);

  static const accent = Color(0xFF3E6FE0);
  static const accentSoft = Color(0xFFEAF0FE);
  static const accentDark = Color(0xFF2E58C4);

  static const danger = Color(0xFFD9362B);
  static const dangerSoft = Color(0x14D9362B);

  static const success = Color(0xFF2F9E5C);
  static const neutralSoft = Color(0xFFF1F0EC);

  static const textPrimary = Color(0xFF17181A);
  static Color textSecondary(double opacity) => textPrimary.withValues(alpha: opacity);
  static Color border(double opacity) => textPrimary.withValues(alpha: opacity);
}

const appFont = 'Barlow';
