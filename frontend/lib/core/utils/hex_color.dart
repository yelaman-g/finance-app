import 'package:flutter/material.dart';

/// Парсит "#RRGGBB" / "#AARRGGBB" в [Color]. При ошибке — [fallback].
Color hexToColor(String? hex, {Color fallback = const Color(0xFF2F6BFF)}) {
  if (hex == null || hex.isEmpty) return fallback;
  var value = hex.replaceAll('#', '').trim();
  if (value.length == 6) value = 'FF$value';
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? fallback : Color(parsed);
}
