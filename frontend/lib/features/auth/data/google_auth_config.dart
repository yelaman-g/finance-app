import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Конфиг Google Sign-In, читаемый из .env. Безопасные дефолты: если dotenv
/// не инициализирован (например, в тестах) — dev-режим включён, clientId пуст.
class GoogleAuthConfig {
  GoogleAuthConfig._();

  static String? get clientId {
    final v = dotenv.isInitialized ? dotenv.env['GOOGLE_CLIENT_ID'] : null;
    return (v == null || v.isEmpty) ? null : v;
  }

  /// true, если явно не задано GOOGLE_DEV_MODE=false.
  static bool get devMode {
    final v = dotenv.isInitialized ? dotenv.env['GOOGLE_DEV_MODE'] : null;
    return v == null ? true : v.toLowerCase() != 'false';
  }
}
