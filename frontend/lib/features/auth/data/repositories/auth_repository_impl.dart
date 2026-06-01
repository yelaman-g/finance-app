import '../../../../core/errors/error_mapper.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../dto/auth_dtos.dart';
import '../mappers/auth_mappers.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required SecureStorage storage,
  })  : _remote = remote,
        _storage = storage;

  final AuthRemoteDataSource _remote;
  final SecureStorage _storage;

  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final dto = await _remote.login(
          LoginRequestDto(email: email, password: password),
        );
        final session = dto.toDomain();
        await _storage.saveTokens(
          access: session.tokens.accessToken,
          refresh: session.tokens.refreshToken,
        );
        return session;
      });

  @override
  Future<Result<AuthSession>> register({
    required String fullName,
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final dto = await _remote.register(
          RegisterRequestDto(
            fullName: fullName,
            email: email,
            password: password,
          ),
        );
        final session = dto.toDomain();
        await _storage.saveTokens(
          access: session.tokens.accessToken,
          refresh: session.tokens.refreshToken,
        );
        return session;
      });

  @override
  Future<Result<AuthUser>> me() =>
      _guard(() async => (await _remote.me()).toDomain());

  @override
  Future<Result<void>> logout() => _guard(() async {
        try {
          await _remote.logout();
        } finally {
          await _storage.clear();
        }
      });

  @override
  Future<Result<void>> forgotPassword({required String email}) =>
      _guard(() => _remote.forgotPassword(email));

  @override
  Future<Result<void>> resetPassword({
    required String code,
    required String newPassword,
  }) =>
      _guard(() => _remote.resetPassword(code: code, newPassword: newPassword));

  @override
  Future<Result<void>> verifyEmail({required String code}) =>
      _guard(() => _remote.verifyEmail(code));

  Future<Result<T>> _guard<T>(Future<T> Function() task) async {
    try {
      return Result.ok(await task());
    } catch (e) {
      return Result.err(mapDioError(e));
    }
  }
}
