import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_result.dart';
import '../../../../core/utils/validators.dart';
import '../state/register_state.dart';
import 'auth_controller.dart';

class RegisterController extends StateNotifier<RegisterState> {
  RegisterController(this._ref) : super(const RegisterState());

  final Ref _ref;

  void fullNameChanged(String v) =>
      state = state.copyWith(fullName: v, fullNameError: null, failure: null);

  void emailChanged(String v) =>
      state = state.copyWith(email: v, emailError: null, failure: null);

  void passwordChanged(String v) => state = state.copyWith(
        password: v,
        passwordError: null,
        confirmPasswordError: null,
        failure: null,
      );

  void confirmPasswordChanged(String v) => state = state.copyWith(
        confirmPassword: v,
        confirmPasswordError: null,
        failure: null,
      );

  // ignore: avoid_positional_boolean_parameters
  void toggleTerms(bool v) => state = state.copyWith(acceptTerms: v);

  bool _validate() {
    final nameErr = Validators.fullName(state.fullName);
    final emailErr = Validators.email(state.email);
    final pwdErr = Validators.password(state.password);
    final confirmErr =
        Validators.confirmPassword(state.confirmPassword, state.password);
    state = state.copyWith(
      fullNameError: nameErr,
      emailError: emailErr,
      passwordError: pwdErr,
      confirmPasswordError: confirmErr,
    );
    return [nameErr, emailErr, pwdErr, confirmErr].every((e) => e == null) &&
        state.acceptTerms;
  }

  Future<bool> submit() async {
    if (!_validate()) return false;
    state = state.copyWith(submitting: true, failure: null);
    final res = await _ref.read(authControllerProvider.notifier).register(
          fullName: state.fullName.trim(),
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

final registerControllerProvider =
    StateNotifierProvider.autoDispose<RegisterController, RegisterState>(
  (ref) => RegisterController(ref),
);
