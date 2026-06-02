import 'package:flutter/material.dart';

/// HIG системная палитра (значения — для светлой темы; brightness-aware
/// семантика — в HigColors ThemeExtension). Имена сохранены для совместимости.
class AppColors {
  AppColors._();

  static const Color brand500 = Color(0xFF007AFF);
  static const Color brand600 = Color(0xFF0062CC);
  static const Color brand400 = Color(0xFF409CFF);
  static const Color brand100 = Color(0xFFD9ECFF);
  static const Color accent = brand500;

  static const Color graphite900 = Color(0xFF000000);
  static const Color graphite800 = Color(0xFF1C1C1E);
  static const Color graphite700 = Color(0xFF3C3C43);
  static const Color graphite500 = Color(0x993C3C43);
  static const Color graphite400 = Color(0x4D3C3C43);
  static const Color graphite300 = Color(0xFFC6C6C8);

  static const Color label = Color(0xFF000000);
  static const Color secondaryLabel = Color(0x993C3C43);
  static const Color separator = Color(0xFFC6C6C8);

  static const Color gray100 = Color(0xFFF2F2F7);
  static const Color gray50 = Color(0xFFF2F2F7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color systemBackground = Color(0xFFF2F2F7);
  static const Color card = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color danger = Color(0xFFFF3B30);

  static const Color shadowSoft = Color(0x0F000000);
  static const Color shadowStrong = Color(0x1F000000);

}
