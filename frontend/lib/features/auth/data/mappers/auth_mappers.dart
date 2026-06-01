import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/auth_user.dart';
import '../dto/auth_dtos.dart';

extension UserDtoMapper on UserDto {
  AuthUser toDomain() => AuthUser(
        id: id,
        email: email,
        fullName: fullName,
        emailVerified: emailVerified,
        avatarUrl: avatarUrl,
        roles: roles,
      );
}

extension AuthTokensDtoMapper on AuthTokensDto {
  AuthTokens toDomain() => AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
}

extension AuthSessionDtoMapper on AuthSessionDto {
  AuthSession toDomain() => AuthSession(
        user: user.toDomain(),
        tokens: tokens.toDomain(),
      );
}
