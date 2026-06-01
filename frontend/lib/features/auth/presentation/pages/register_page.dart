import 'package:flutter/material.dart';
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
import '../controllers/register_controller.dart';
import '../state/register_state.dart';

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

    ref.listen<RegisterState>(registerControllerProvider, (prev, next) {
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
                    const SizedBox(height: AppSpacing.xxl),
                    const _BackToLogin(),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Create your account', style: AppTypography.h1),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Join AIFB and bring your family budget into one place.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    PremiumTextField(
                      label: 'Full name',
                      hint: 'Aibek Sultanov',
                      controller: _nameCtrl,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.person_outline_rounded,
                      autofillHints: const [AutofillHints.name],
                      errorText: state.fullNameError,
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                      hint: 'At least 8 characters',
                      controller: _passwordCtrl,
                      obscure: true,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.lock_outline_rounded,
                      autofillHints: const [AutofillHints.newPassword],
                      errorText: state.passwordError,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PremiumTextField(
                      label: 'Confirm password',
                      hint: 'Repeat your password',
                      controller: _confirmCtrl,
                      obscure: true,
                      textInputAction: TextInputAction.go,
                      prefixIcon: Icons.lock_reset_rounded,
                      autofillHints: const [AutofillHints.newPassword],
                      errorText: state.confirmPasswordError,
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _TermsTile(
                      value: state.acceptTerms,
                      onChanged: _ctrl.toggleTerms,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Create account',
                      onPressed: state.submitting ? null : _submit,
                      loading: state.submitting,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: AppTypography.caption,
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.login.path),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.brand600,
                          ),
                          child: Text(
                            'Sign in',
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

class _BackToLogin extends StatelessWidget {
  const _BackToLogin();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () => context.go(AppRoutes.login.path),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: AppColors.brand600,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Back to sign in',
                style: AppTypography.caption.copyWith(
                  color: AppColors.brand600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
                activeColor: AppColors.brand600,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'I agree to the Terms of Service and Privacy Policy.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.graphite700,
                ),
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
