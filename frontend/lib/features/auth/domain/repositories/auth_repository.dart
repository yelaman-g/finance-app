import '../../../../core/network/api_result.dart';
import '../entities/auth_session.dart';
import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  });

  Future<Result<AuthSession>> register({
    required String fullName,
    required String email,
    required String password,
  });

  Future<Result<AuthSession>> signInWithGoogle({required String idToken});

  Future<Result<AuthUser>> me();

  Future<Result<void>> logout();

  Future<Result<String?>> forgotPassword({required String email});

  Future<Result<void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<Result<void>> verifyEmail({required String code});
}
