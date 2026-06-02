import 'package:aifb/app/theme/app_typography.dart';
import 'package:aifb/app/theme/hig_colors.dart';
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light, HigColors.light);
  static ThemeData get dark => _build(Brightness.dark, HigColors.dark);

  static ThemeData _build(Brightness brightness, HigColors hig) {
    final scheme = ColorScheme.fromSeed(
      seedColor: hig.accent,
      brightness: brightness,
      primary: hig.accent,
      surface: hig.card,
      error: hig.danger,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: hig.pageBackground,
      fontFamily: 'Inter',
      extensions: [hig],
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textTheme: TextTheme(
        displayLarge: AppTypography.display.copyWith(color: hig.label),
        headlineLarge: AppTypography.h1.copyWith(color: hig.label),
        headlineMedium: AppTypography.h2.copyWith(color: hig.label),
        titleMedium: AppTypography.headline.copyWith(color: hig.label),
        bodyLarge: AppTypography.body.copyWith(color: hig.label),
        bodyMedium: AppTypography.subhead.copyWith(color: hig.secondaryLabel),
        bodySmall: AppTypography.footnote.copyWith(color: hig.secondaryLabel),
        labelLarge: AppTypography.button.copyWith(color: hig.accent),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: hig.pageBackground,
        foregroundColor: hig.label,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: hig.card,
        indicatorColor: hig.accent.withValues(alpha: 0.16),
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          AppTypography.caption.copyWith(color: hig.secondaryLabel),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? hig.accent
                : hig.secondaryLabel,
          ),
        ),
      ),
      dividerTheme:
          DividerThemeData(color: hig.separator, thickness: 0.5, space: 0.5),
    );
  }
}
