import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';

@freezed
class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String id,
    required String email,
    required String fullName,
    required bool emailVerified,
    String? avatarUrl,
    @Default(<String>[]) List<String> roles,
  }) = _AuthUser;
}
