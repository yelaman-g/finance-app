import 'dart:convert';

import 'package:aifb/features/auth/data/google_sign_in_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('в dev-режиме возвращает корректный dev-токен', () async {
    // dotenv не инициализирован в тестах → GoogleAuthConfig.devMode == true
    final service = GoogleSignInService();
    final token = await service.obtainIdToken();

    expect(token, isNotNull);
    expect(token, startsWith('dev.'));

    final payload = token!.substring('dev.'.length);
    // base64Url без паддинга → дополняем для декодирования
    final normalized = base64Url.normalize(payload);
    final json =
        jsonDecode(utf8.decode(base64Url.decode(normalized))) as Map<String, dynamic>;
    expect(json['email'], isA<String>());
    expect(json['sub'], isA<String>());
    expect(json['email_verified'], true);
  });
}
