import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_providers.dart';
import '../state/auth_state.dart';

/// Owns the global session lifecycle.
class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthRepository repository,
    required SecureStorage storage,
    required Ref ref,
  })  : _repo = repository,
        _storage = storage,
        _ref = ref,
        super(const AuthState.unknown()) {
    _bootstrap();
    // Force-logout when the auth interceptor reports a refresh failure.
    _ref.listen<int>(authFailureSignalProvider, (prev, next) {
      if (prev != null && next > prev) {
        state = const AuthState.unauthenticated();
      }
    });
  }

  final AuthRepository _repo;
  final SecureStorage _storage;
  final Ref _ref;

  Future<void> _bootstrap() async {
    final access = await _storage.readAccess();
    if (access == null || access.isEmpty) {
      state = const AuthState.unauthenticated();
      return;
    }
    final res = await _repo.me();
    state = switch (res) {
      Ok(:final value) => AuthState.authenticated(value),
      Err() => const AuthState.unauthenticated(),
    };
  }

  Future<Result<void>> login({
    required String email,
    required String password,
  }) async {
    final res = await _repo.login(email: email, password: password);
    switch (res) {
      case Ok(:final value):
        state = AuthState.authenticated(value.user);
        return const Result.ok(null);
      case Err(:final failure):
        state = AuthState.unauthenticated(lastFailure: failure);
        return Result.err(failure);
    }
  }

  Future<Result<void>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final res = await _repo.register(
      fullName: fullName,
      email: email,
      password: password,
    );
    switch (res) {
      case Ok(:final value):
        state = AuthState.authenticated(value.user);
        return const Result.ok(null);
      case Err(:final failure):
        state = AuthState.unauthenticated(lastFailure: failure);
        return Result.err(failure);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState.unauthenticated();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    repository: ref.watch(authRepositoryProvider),
    storage: ref.watch(secureStorageProvider),
    ref: ref,
  );
});
