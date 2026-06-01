import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Bare Dio for refresh calls (no auth interceptor).
final refreshDioProvider = Provider<Dio>((ref) {
  return _baseDio()..interceptors.add(buildLoggingInterceptor());
});

/// Authenticated Dio used by all repositories.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final refreshDio = ref.watch(refreshDioProvider);
  final dio = _baseDio();
  dio.interceptors.addAll([
    AuthInterceptor(
      storage: storage,
      refreshDio: refreshDio,
      onAuthFailure: () async {
        ref.read(authFailureSignalProvider.notifier).state++;
      },
    ),
    buildLoggingInterceptor(),
  ]);
  return dio;
});

/// Incremented every time the auth interceptor fails to refresh.
/// AuthController listens and forces logout.
final authFailureSignalProvider = StateProvider<int>((_) => 0);

Dio _baseDio() {
  final fromEnv =
      dotenv.isInitialized ? dotenv.env['API_BASE_URL'] : null;
  final base = fromEnv ?? 'http://localhost:9090/api/v1';
  return Dio(
    BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
      responseType: ResponseType.json,
      validateStatus: (s) => s != null && s < 500,
    ),
  );
}
