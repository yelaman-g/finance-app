import 'package:freezed_annotation/freezed_annotation.dart';

import 'auth_tokens.dart';
import 'auth_user.dart';

part 'auth_session.freezed.dart';

@freezed
class AuthSession with _$AuthSession {
  const factory AuthSession({
    required AuthUser user,
    required AuthTokens tokens,
  }) = _AuthSession;
}
