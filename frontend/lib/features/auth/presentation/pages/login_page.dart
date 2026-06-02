import 'package:aifb/app/router/routes.dart';
import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/core/errors/failure.dart';
import 'package:aifb/features/auth/presentation/controllers/login_controller.dart';
import 'package:aifb/features/auth/presentation/state/login_state.dart';
import 'package:aifb/shared/widgets/hig_button.dart';
import 'package:aifb/shared/widgets/hig_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_syncEmail);
    _passwordCtrl.addListener(_syncPassword);
  }

  @override
  void dispose() {
    _emailCtrl
      ..removeListener(_syncEmail)
      ..dispose();
    _passwordCtrl
      ..removeListener(_syncPassword)
      ..dispose();
    super.dispose();
  }

  void _syncEmail() =>
      ref.read(loginControllerProvider.notifier).emailChanged(_emailCtrl.text);

  void _syncPassword() => ref
      .read(loginControllerProvider.notifier)
      .passwordChanged(_passwordCtrl.text);

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref.read(loginControllerProvider.notifier).submit();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final hig = HigColors.of(context);

    ref.listen<LoginState>(loginControllerProvider, (prev, next) {
      final f = next.failure;
      if (f != null && f != prev?.failure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_failureMessage(f))));
      }
    });

    return Scaffold(
      backgroundColor: hig.pageBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'AIFB',
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Вход',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                HigTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  errorText: state.emailError,
                ),
                const SizedBox(height: 12),
                HigTextField(
                  controller: _passwordCtrl,
                  label: 'Пароль',
                  obscureText: true,
                  errorText: state.passwordError,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        context.push(AppRoutes.forgotPassword.path),
                    child: const Text('Забыли пароль?'),
                  ),
                ),
                const SizedBox(height: 12),
                HigButton(
                  label: 'Войти',
                  loading: state.submitting,
                  onPressed: state.submitting ? null : _submit,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Нет аккаунта?'),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.register.path),
                      child: const Text('Создать аккаунт'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _failureMessage(Failure f) {
  return switch (f) {
    NetworkFailure(:final message) =>
      message ?? 'No internet connection. Please try again.',
    TimeoutFailure() => 'Request timed out. Please try again.',
    UnauthorizedFailure(:final message) =>
      message ?? 'Invalid email or password.',
    ForbiddenFailure(:final message) => message ?? 'Access denied.',
    NotFoundFailure(:final message) => message ?? 'Not found.',
    ConflictFailure(:final message) => message ?? 'Account already exists.',
    ValidationFailure(:final message) => message,
    ServerFailure(:final message) =>
      message ?? 'Server error. Please try again.',
    UnknownFailure(:final message) =>
      message ?? 'Something went wrong. Please try again.',
  };
}
