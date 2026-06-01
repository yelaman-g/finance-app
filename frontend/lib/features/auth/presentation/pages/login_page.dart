import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/failure.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/premium_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../controllers/login_controller.dart';
import '../state/login_state.dart';

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

    ref.listen<LoginState>(loginControllerProvider, (prev, next) {
      final f = next.failure;
      if (f != null && f != prev?.failure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_failureMessage(f))));
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xxxl),
                    const _BrandMark(),
                    const SizedBox(height: AppSpacing.xxl),
                    Text('Welcome back', style: AppTypography.h1),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Sign in to continue managing your family budget.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    PremiumTextField(
                      label: 'Email',
                      hint: 'you@example.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.alternate_email_rounded,
                      autofillHints: const [AutofillHints.email],
                      errorText: state.emailError,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PremiumTextField(
                      label: 'Password',
                      hint: 'Your password',
                      controller: _passwordCtrl,
                      obscure: true,
                      textInputAction: TextInputAction.go,
                      prefixIcon: Icons.lock_outline_rounded,
                      autofillHints: const [AutofillHints.password],
                      errorText: state.passwordError,
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            context.push(AppRoutes.forgotPassword.path),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          foregroundColor: AppColors.brand600,
                        ),
                        child: Text(
                          'Forgot password?',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.brand600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Sign in',
                      onPressed: state.submitting ? null : _submit,
                      loading: state.submitting,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('New to AIFB?', style: AppTypography.caption),
                        TextButton(
                          onPressed: () =>
                              context.go(AppRoutes.register.path),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.brand600,
                          ),
                          child: Text(
                            'Create account',
                            style: AppTypography.title.copyWith(
                              color: AppColors.brand600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 380.ms)
                    .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.brand500, AppColors.brand400],
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(
            Icons.account_balance_rounded,
            color: AppColors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text('AIFB', style: AppTypography.h2),
      ],
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
