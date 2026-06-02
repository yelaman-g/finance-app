import 'package:flutter/material.dart';

/// HIG-типографика на Inter. Цвет берётся из темы (textTheme/DefaultTextStyle).
class AppTypography {
  AppTypography._();

  static const String _family = 'Inter';

  static const TextStyle display = TextStyle(
    fontFamily: _family,
    fontSize: 34,
    height: 1.12,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );
  static const TextStyle h1 = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle headline = TextStyle(
    fontFamily: _family,
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle title = TextStyle(
    fontFamily: _family,
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontSize: 17,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle subhead = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    height: 1.35,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle footnote = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle button = TextStyle(
    fontFamily: _family,
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );
}
