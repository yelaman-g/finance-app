import 'dart:convert';

import 'package:aifb/features/auth/data/google_auth_config.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInException implements Exception {
  GoogleSignInException(this.message);
  final String message;
  @override
  String toString() => 'GoogleSignInException: $message';
}

/// Возвращает Google ID-token для отправки на backend.
/// В dev-режиме собирает неподписанный `dev.<base64url>`-токен и НЕ обращается к
/// плагину (на эмуляторе без OAuth-client плагин упал бы). В prod-режиме
/// использует google_sign_in с serverClientId = GOOGLE_CLIENT_ID.
class GoogleSignInService {
  GoogleSignInService({GoogleSignIn? googleSignIn}) : _injected = googleSignIn;

  final GoogleSignIn? _injected;

  /// Возвращает idToken, либо null если пользователь отменил вход.
  Future<String?> obtainIdToken() async {
    if (GoogleAuthConfig.devMode) {
      return _devToken('demo@gmail.com', 'Demo Google User');
    }
    final signIn =
        _injected ?? GoogleSignIn(serverClientId: GoogleAuthConfig.clientId);
    final account = await signIn.signIn();
    if (account == null) {
      return null; // отмена пользователем
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw GoogleSignInException('Google не вернул ID-token');
    }
    return idToken;
  }

  static String _devToken(String email, String name) {
    final json = jsonEncode(<String, dynamic>{
      'sub': 'dev-$email',
      'email': email,
      'name': name,
      'email_verified': true,
    });
    final payload = base64Url.encode(utf8.encode(json)).replaceAll('=', '');
    return 'dev.$payload';
  }
}
