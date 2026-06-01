import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/failure.dart';

part 'forgot_password_state.freezed.dart';

@freezed
class ForgotPasswordState with _$ForgotPasswordState {
  const factory ForgotPasswordState({
    @Default('') String email,
    String? emailError,
    @Default(false) bool submitting,
    @Default(false) bool sent,
    Failure? failure,
  }) = _ForgotPasswordState;
}
