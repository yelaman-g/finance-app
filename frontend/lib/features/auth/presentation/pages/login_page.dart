import 'package:aifb/app/router/routes.dart';
import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/core/errors/failure_message.dart';
import 'package:aifb/features/auth/presentation/controllers/login_controller.dart';
import 'package:aifb/features/auth/presentation/state/login_state.dart';
import 'package:aifb/shared/widgets/hig_button.dart';
import 'package:aifb/shared/widgets/hig_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showEmailForm = false;

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

  Future<void> _googleSignIn() async {
    FocusScope.of(context).unfocus();
    // Навигация управляется AuthState (redirect роутера); возврат намеренно игнорируем.
    await ref.read(loginControllerProvider.notifier).signInWithGoogle();
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
          ..showSnackBar(SnackBar(content: Text(f.userMessage)));
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
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    key: const Key('google_sign_in_button'),
                    onPressed: state.submitting ? null : _googleSignIn,
                    icon: SvgPicture.asset(
                      'assets/google_logo.svg',
                      height: 20,
                      width: 20,
                    ),
                    label: const Text('Войти через Google'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: hig.separator),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!_showEmailForm)
                  TextButton(
                    onPressed: () => setState(() => _showEmailForm = true),
                    child: const Text('Войти с Email'),
                  )
                else ...[
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
                ],
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

