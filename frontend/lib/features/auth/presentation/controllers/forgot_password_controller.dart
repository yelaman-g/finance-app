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

  Future<bool> submit() async {
    final err = Validators.email(state.email);
    if (err != null) {
      state = state.copyWith(emailError: err);
      return false;
    }
    state = state.copyWith(submitting: true, failure: null);
    final res = await _ref
        .read(authRepositoryProvider)
        .forgotPassword(email: state.email.trim());
    switch (res) {
      case Ok():
        state = state.copyWith(submitting: false, sent: true);
        return true;
      case Err(:final failure):
        state = state.copyWith(submitting: false, failure: failure);
        return false;
    }
  }
}

final forgotPasswordControllerProvider = StateNotifierProvider.autoDispose<
    ForgotPasswordController, ForgotPasswordState>(
  (ref) => ForgotPasswordController(ref),
);
