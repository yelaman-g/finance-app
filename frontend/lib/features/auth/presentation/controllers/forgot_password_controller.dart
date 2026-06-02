import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_result.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';
import '../state/forgot_password_state.dart';

class ForgotPasswordController extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordController(this._ref) : super(const ForgotPasswordState());

  final Ref _ref;

  void emailChanged(String v) =>
      state = state.copyWith(email: v, emailError: null, failure: null);

  void codeChanged(String v) =>
      state = state.copyWith(code: v, codeError: null, failure: null);

  void newPasswordChanged(String v) => state =
      state.copyWith(newPassword: v, newPasswordError: null, failure: null);

  Future<void> requestCode() async {
    final err = Validators.email(state.email);
    if (err != null) {
      state = state.copyWith(emailError: err);
      return;
    }
    state = state.copyWith(submitting: true, failure: null);
    final res = await _ref
        .read(authRepositoryProvider)
        .forgotPassword(email: state.email.trim());
    switch (res) {
      case Ok(:final value):
        state = state.copyWith(
          submitting: false,
          step: ForgotStep.reset,
          devCode: value,
        );
      case Err(:final failure):
        state = state.copyWith(submitting: false, failure: failure);
    }
  }

  Future<void> reset() async {
    final codeErr = Validators.code(state.code);
    final pwErr = Validators.password(state.newPassword);
    if (codeErr != null || pwErr != null) {
      state = state.copyWith(codeError: codeErr, newPasswordError: pwErr);
      return;
    }
    state = state.copyWith(resetSubmitting: true, failure: null);
    final res = await _ref.read(authRepositoryProvider).resetPassword(
          email: state.email.trim(),
          code: state.code.trim(),
          newPassword: state.newPassword,
        );
    switch (res) {
      case Ok():
        state = state.copyWith(resetSubmitting: false, resetDone: true);
      case Err(:final failure):
        state = state.copyWith(resetSubmitting: false, failure: failure);
    }
  }

  void backToRequest() => state = state.copyWith(
        step: ForgotStep.request,
        devCode: null,
        failure: null,
        codeError: null,
        newPasswordError: null,
      );
}

final forgotPasswordControllerProvider = StateNotifierProvider.autoDispose<
    ForgotPasswordController, ForgotPasswordState>(
  (ref) => ForgotPasswordController(ref),
);
