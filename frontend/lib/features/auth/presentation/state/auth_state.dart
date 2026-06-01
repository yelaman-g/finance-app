import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/auth_user.dart';

part 'auth_state.freezed.dart';

/// Global session state.
/// - [unknown]: app is bootstrapping; router shows splash.
/// - [authenticated]: a verified session exists.
/// - [unauthenticated]: no session; auth screens are shown.
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.unknown() = AuthUnknown;
  const factory AuthState.authenticated(AuthUser user) = AuthAuthenticated;
  const factory AuthState.unauthenticated({Failure? lastFailure}) =
      AuthUnauthenticated;
}
