import 'package:flutter/material.dart';

/// Premium fintech palette: white, soft blue, graphite, light gray.
/// No purple. No aggressive saturation.
class AppColors {
  AppColors._();

  // Brand
  static const Color brand500 = Color(0xFF2F6BFF); // soft blue, primary action
  static const Color brand600 = Color(0xFF1F55E6);
  static const Color brand400 = Color(0xFF6A93FF);
  static const Color brand100 = Color(0xFFE6EEFF);

  // Neutrals
  static const Color graphite900 = Color(0xFF0B1020);
  static const Color graphite800 = Color(0xFF161B2B);
  static const Color graphite700 = Color(0xFF2A3147);
  static const Color graphite500 = Color(0xFF5A6378);
  static const Color graphite400 = Color(0xFF8A93A7);
  static const Color graphite300 = Color(0xFFB7BECC);

  static const Color gray100 = Color(0xFFF4F6FB);
  static const Color gray50 = Color(0xFFF9FAFD);
  static const Color white = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF12B886);
  static const Color warning = Color(0xFFF59F00);
  static const Color danger = Color(0xFFE03131);

  // Glass
  static const Color glassWhite = Color(0x99FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Shadows
  static const Color shadowSoft = Color(0x14101828);
  static const Color shadowStrong = Color(0x29101828);
}
