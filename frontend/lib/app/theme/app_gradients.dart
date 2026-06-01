import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppGradients {
  AppGradients._();

  /// Background gradient for auth screens — calm, premium, white→soft blue.
  static const LinearGradient authBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.white,
      Color(0xFFF1F5FF),
      Color(0xFFE6EEFF),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// Primary CTA gradient.
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brand500, AppColors.brand600],
  );

  /// Decorative orb behind glass cards.
  static const RadialGradient orb = RadialGradient(
    colors: [Color(0x66A8C2FF), Color(0x002F6BFF)],
    radius: 0.7,
  );
}
