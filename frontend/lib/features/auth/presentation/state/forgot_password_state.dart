import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/failure.dart';

part 'forgot_password_state.freezed.dart';

enum ForgotStep { request, reset }

@freezed
class ForgotPasswordState with _$ForgotPasswordState {
  const factory ForgotPasswordState({
    @Default(ForgotStep.request) ForgotStep step,
    @Default('') String email,
    String? emailError,
    @Default(false) bool submitting,
    String? devCode,
    @Default('') String code,
    String? codeError,
    @Default('') String newPassword,
    String? newPasswordError,
    @Default(false) bool resetSubmitting,
    @Default(false) bool resetDone,
    Failure? failure,
  }) = _ForgotPasswordState;
}
