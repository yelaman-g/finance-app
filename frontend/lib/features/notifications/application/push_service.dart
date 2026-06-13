import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../firebase_options.dart';
import '../data/fcm_config.dart';
import '../domain/repositories/push_repository.dart';

/// Регистрация/снятие device-токена. В dev-режиме (FCM_DEV_MODE=true) использует
/// синтетический токен — реальный Firebase не требуется. В проде получает FCM-токен.
class PushService {
  PushService(this._repo);
  final PushRepository _repo;

  /// Инициализация Firebase под guard — dummy-конфиг не должен валить приложение.
  static Future<void> initFirebase() async {
    if (FcmConfig.devMode) return; // в dev реальный Firebase не нужен
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase init skipped: $e');
    }
  }

  /// Включить уведомления: получить токен и зарегистрировать на backend.
  Future<void> enable() async {
    final token = await _obtainToken();
    if (token == null) return;
    await _repo.registerToken(token, _platform());
  }

  /// Выключить: снять текущий токен.
  Future<void> disable() async {
    final token = await _obtainToken();
    if (token == null) return;
    await _repo.deleteToken(token);
  }

  Future<String?> _obtainToken() async {
    if (FcmConfig.devMode) {
      return 'dev-${defaultTargetPlatform.name}-token';
    }
    try {
      await FirebaseMessaging.instance.requestPermission();
      return FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('FCM getToken failed: $e');
      return null;
    }
  }

  String _platform() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'IOS';
      case TargetPlatform.android:
        return 'ANDROID';
      default:
        return 'WEB';
    }
  }
}
