import 'dart:async';

import 'package:dio/dio.dart';

import '../../storage/secure_storage.dart';
import '../api_endpoints.dart';

/// Attaches access token; on 401 refreshes once (single-flight) and retries.
/// On refresh failure → clears tokens and surfaces 401 so `AuthController`
/// can drop the user back to the login screen.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.storage,
    required this.refreshDio,
    required this.onAuthFailure,
  });

  final SecureStorage storage;

  /// Separate Dio used for the refresh call so it never re-enters this
  /// interceptor and deadlocks.
  final Dio refreshDio;

  final Future<void> Function() onAuthFailure;

  Completer<String?>? _refreshLock;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] == true) {
      return handler.next(options);
    }
    final token = await storage.readAccess();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;
    final isAuthEndpoint = path.contains(ApiEndpoints.refresh) ||
        path.contains(ApiEndpoints.login) ||
        path.contains(ApiEndpoints.register);

    if (status != 401 || isAuthEndpoint) {
      return handler.next(err);
    }
    if (err.requestOptions.extra['retried'] == true) {
      await _failAuth();
      return handler.next(err);
    }

    final newAccess = await _refreshTokens();
    if (newAccess == null) {
      await _failAuth();
      return handler.next(err);
    }

    final retryOptions = err.requestOptions
      ..headers['Authorization'] = 'Bearer $newAccess'
      ..extra['retried'] = true;

    try {
      final response = await refreshDio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<String?> _refreshTokens() {
    final inFlight = _refreshLock;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<String?>();
    _refreshLock = completer;

    unawaited(
      _doRefresh().then((value) {
        completer.complete(value);
        _refreshLock = null;
      }).catchError((Object _) {
        completer.complete(null);
        _refreshLock = null;
      }),
    );

    return completer.future;
  }

  Future<String?> _doRefresh() async {
    final refresh = await storage.readRefresh();
    if (refresh == null || refresh.isEmpty) return null;
    try {
      final res = await refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.refresh,
        data: {'refreshToken': refresh},
        options: Options(extra: {'skipAuth': true}),
      );
      final data = res.data?['data'] as Map<String, dynamic>?;
      final access = data?['accessToken'] as String?;
      final newRefresh = data?['refreshToken'] as String?;
      if (access == null || newRefresh == null) return null;
      await storage.saveTokens(access: access, refresh: newRefresh);
      return access;
    } on DioException {
      return null;
    }
  }

  Future<void> _failAuth() async {
    await storage.clear();
    await onAuthFailure();
  }
}
