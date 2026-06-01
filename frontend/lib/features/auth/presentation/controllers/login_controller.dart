import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_result.dart';
import '../../../../core/utils/validators.dart';
import '../state/login_state.dart';
import 'auth_controller.dart';

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._ref) : super(const LoginState());

  final Ref _ref;

  void emailChanged(String v) =>
      state = state.copyWith(email: v, emailError: null, failure: null);

  void passwordChanged(String v) =>
      state = state.copyWith(password: v, passwordError: null, failure: null);

  bool _validate() {
    final emailErr = Validators.email(state.email);
    final pwdErr =
        state.password.isEmpty ? 'Password is required' : null;
    state = state.copyWith(emailError: emailErr, passwordError: pwdErr);
    return emailErr == null && pwdErr == null;
  }

  Future<bool> submit() async {
    if (!_validate()) return false;
    state = state.copyWith(submitting: true, failure: null);
    final res = await _ref.read(authControllerProvider.notifier).login(
          email: state.email.trim(),
          password: state.password,
        );
    final ok = res is Ok<void>;
    state = state.copyWith(
      submitting: false,
      failure: ok ? null : (res as Err<void>).failure,
    );
    return ok;
  }
}

final loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, LoginState>((ref) {
  return LoginController(ref);
});
