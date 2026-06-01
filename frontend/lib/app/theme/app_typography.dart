import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const String _family = 'SF Pro Display';

  static const TextStyle display = TextStyle(
    fontFamily: _family,
    fontSize: 34,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: AppColors.graphite900,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppColors.graphite900,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.graphite900,
  );

  static const TextStyle title = TextStyle(
    fontFamily: _family,
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.graphite900,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.graphite700,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: AppColors.graphite500,
  );

  static const TextStyle button = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.white,
  );
}
