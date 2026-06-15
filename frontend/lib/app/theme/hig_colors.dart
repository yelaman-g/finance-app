import 'package:flutter/material.dart';

@immutable
class HigColors extends ThemeExtension<HigColors> {
  const HigColors({
    required this.pageBackground,
    required this.card,
    required this.label,
    required this.secondaryLabel,
    required this.separator,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color pageBackground;
  final Color card;
  final Color label;
  final Color secondaryLabel;
  final Color separator;
  final Color accent;
  final Color success;
  final Color warning;
  final Color danger;

  static const light = HigColors(
    pageBackground: Color(0xFFF2F2F7),
    card: Color(0xFFFFFFFF),
    label: Color(0xFF000000),
    secondaryLabel: Color(0x993C3C43),
    separator: Color(0xFFC6C6C8),
    accent: Color(0xFF007AFF),
    success: Color(0xFF34C759),
    warning: Color(0xFFFF9F0A),
    danger: Color(0xFFFF3B30),
  );

  static const dark = HigColors(
    pageBackground: Color(0xFF000000),
    card: Color(0xFF1C1C1E),
    label: Color(0xFFFFFFFF),
    secondaryLabel: Color(0x99EBEBF5),
    separator: Color(0xFF38383A),
    accent: Color(0xFF0A84FF),
    success: Color(0xFF30D158),
    warning: Color(0xFFFF9F0A),
    danger: Color(0xFFFF453A),
  );

  static HigColors of(BuildContext context) =>
      Theme.of(context).extension<HigColors>() ?? light;

  @override
  HigColors copyWith({
    Color? pageBackground,
    Color? card,
    Color? label,
    Color? secondaryLabel,
    Color? separator,
    Color? accent,
    Color? success,
    Color? warning,
    Color? danger,
  }) =>
      HigColors(
        pageBackground: pageBackground ?? this.pageBackground,
        card: card ?? this.card,
        label: label ?? this.label,
        secondaryLabel: secondaryLabel ?? this.secondaryLabel,
        separator: separator ?? this.separator,
        accent: accent ?? this.accent,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
      );

  @override
  HigColors lerp(ThemeExtension<HigColors>? other, double t) {
    if (other is! HigColors) return this;
    return HigColors(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      card: Color.lerp(card, other.card, t)!,
      label: Color.lerp(label, other.label, t)!,
      secondaryLabel: Color.lerp(secondaryLabel, other.secondaryLabel, t)!,
      separator: Color.lerp(separator, other.separator, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}
