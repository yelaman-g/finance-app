import 'package:aifb/app/router/routes.dart';
import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/core/errors/failure.dart';
import 'package:aifb/features/auth/presentation/controllers/register_controller.dart';
import 'package:aifb/features/auth/presentation/state/register_state.dart';
import 'package:aifb/shared/widgets/hig_button.dart';
import 'package:aifb/shared/widgets/hig_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_syncName);
    _emailCtrl.addListener(_syncEmail);
    _passwordCtrl.addListener(_syncPassword);
    _confirmCtrl.addListener(_syncConfirm);
  }

  @override
  void dispose() {
    _nameCtrl
      ..removeListener(_syncName)
      ..dispose();
    _emailCtrl
      ..removeListener(_syncEmail)
      ..dispose();
    _passwordCtrl
      ..removeListener(_syncPassword)
      ..dispose();
    _confirmCtrl
      ..removeListener(_syncConfirm)
      ..dispose();
    super.dispose();
  }

  RegisterController get _ctrl =>
      ref.read(registerControllerProvider.notifier);

  void _syncName() => _ctrl.fullNameChanged(_nameCtrl.text);
  void _syncEmail() => _ctrl.emailChanged(_emailCtrl.text);
  void _syncPassword() => _ctrl.passwordChanged(_passwordCtrl.text);
  void _syncConfirm() => _ctrl.confirmPasswordChanged(_confirmCtrl.text);

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await _ctrl.submit();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerControllerProvider);
    final hig = HigColors.of(context);

    ref.listen<RegisterState>(registerControllerProvider, (prev, next) {
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
                  'Регистрация',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                HigTextField(
                  controller: _nameCtrl,
                  label: 'Полное имя',
                  keyboardType: TextInputType.text,
                  errorText: state.fullNameError,
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                HigTextField(
                  controller: _confirmCtrl,
                  label: 'Подтвердите пароль',
                  obscureText: true,
                  errorText: state.confirmPasswordError,
                ),
                const SizedBox(height: 16),
                _TermsTile(
                  value: state.acceptTerms,
                  onChanged: _ctrl.toggleTerms,
                ),
                const SizedBox(height: 20),
                HigButton(
                  label: 'Создать аккаунт',
                  loading: state.submitting,
                  onPressed: state.submitting ? null : _submit,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Уже есть аккаунт?'),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login.path),
                      child: const Text('Войти'),
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

class _TermsTile extends StatelessWidget {
  const _TermsTile({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Я принимаю Условия использования и Политику конфиденциальности.',
              ),
            ),
          ],
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
      message ?? 'Authentication failed.',
    ForbiddenFailure(:final message) => message ?? 'Access denied.',
    NotFoundFailure(:final message) => message ?? 'Not found.',
    ConflictFailure(:final message) =>
      message ?? 'An account with this email already exists.',
    ValidationFailure(:final message) => message,
    ServerFailure(:final message) =>
      message ?? 'Server error. Please try again.',
    UnknownFailure(:final message) =>
      message ?? 'Something went wrong. Please try again.',
  };
}
