import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
        brightness: Brightness.light,
        scaffold: AppColors.gray50,
        surface: AppColors.white,
        onSurface: AppColors.graphite900,
        onSurfaceMuted: AppColors.graphite500,
        outline: AppColors.gray100,
        inputFill: AppColors.white,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        scaffold: AppColors.graphite900,
        surface: AppColors.graphite800,
        onSurface: AppColors.white,
        onSurfaceMuted: AppColors.graphite300,
        outline: AppColors.graphite700,
        inputFill: AppColors.graphite800,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color onSurface,
    required Color onSurfaceMuted,
    required Color outline,
    required Color inputFill,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand500,
      brightness: brightness,
      primary: AppColors.brand500,
      surface: surface,
      onSurface: onSurface,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textTheme: TextTheme(
        displayLarge: AppTypography.display.copyWith(color: onSurface),
        headlineLarge: AppTypography.h1.copyWith(color: onSurface),
        headlineMedium: AppTypography.h2.copyWith(color: onSurface),
        titleMedium: AppTypography.title.copyWith(color: onSurface),
        bodyMedium: AppTypography.body.copyWith(color: onSurfaceMuted),
        bodySmall: AppTypography.caption.copyWith(color: onSurfaceMuted),
        labelLarge: AppTypography.button,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: AppTypography.body.copyWith(color: onSurfaceMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.brand500, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
    );
  }
}
