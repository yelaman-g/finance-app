import 'package:aifb/app/router/routes.dart';
import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/core/errors/failure_message.dart';
import 'package:aifb/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:aifb/features/auth/presentation/state/forgot_password_state.dart';
import 'package:aifb/shared/widgets/hig_button.dart';
import 'package:aifb/shared/widgets/hig_text_field.dart';
import 'package:aifb/shared/widgets/inset_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_syncEmail);
    _codeCtrl.addListener(_syncCode);
    _passwordCtrl.addListener(_syncPassword);
  }

  @override
  void dispose() {
    _emailCtrl
      ..removeListener(_syncEmail)
      ..dispose();
    _codeCtrl
      ..removeListener(_syncCode)
      ..dispose();
    _passwordCtrl
      ..removeListener(_syncPassword)
      ..dispose();
    super.dispose();
  }

  void _syncEmail() => ref
      .read(forgotPasswordControllerProvider.notifier)
      .emailChanged(_emailCtrl.text);

  void _syncCode() => ref
      .read(forgotPasswordControllerProvider.notifier)
      .codeChanged(_codeCtrl.text);

  void _syncPassword() => ref
      .read(forgotPasswordControllerProvider.notifier)
      .newPasswordChanged(_passwordCtrl.text);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final hig = HigColors.of(context);

    ref.listen<ForgotPasswordState>(forgotPasswordControllerProvider,
        (prev, next) {
      final f = next.failure;
      if (f != null && f != prev?.failure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(f.userMessage)));
      }
      if (next.resetDone && !(prev?.resetDone ?? false)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Пароль изменён')));
        context.go(AppRoutes.login.path);
      }
    });

    return Scaffold(
      backgroundColor: hig.pageBackground,
      appBar: AppBar(
        backgroundColor: hig.pageBackground,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: () => context.go(AppRoutes.login.path)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: state.step == ForgotStep.request
                  ? _requestStep(context, state, hig)
                  : _resetStep(context, state, hig),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _requestStep(
    BuildContext context,
    ForgotPasswordState state,
    HigColors hig,
  ) =>
      [
        Text(
          'Восстановление',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Введите email — пришлём код для сброса пароля',
          style: TextStyle(color: hig.secondaryLabel),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        HigTextField(
          controller: _emailCtrl,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          errorText: state.emailError,
        ),
        const SizedBox(height: 16),
        HigButton(
          label: 'Получить код',
          loading: state.submitting,
          onPressed: state.submitting
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  ref
                      .read(forgotPasswordControllerProvider.notifier)
                      .requestCode();
                },
        ),
      ];

  List<Widget> _resetStep(
    BuildContext context,
    ForgotPasswordState state,
    HigColors hig,
  ) =>
      [
        Text(
          'Новый пароль',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (state.devCode != null)
          InsetSection(
            header: 'dev-режим',
            children: [
              InsetTile(
                title: state.devCode!,
                subtitle: 'В проде код придёт на почту',
              ),
            ],
          )
        else
          Text(
            'Если email зарегистрирован, код отправлен',
            style: TextStyle(color: hig.secondaryLabel),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),
        HigTextField(
          controller: _codeCtrl,
          label: 'Код из 6 цифр',
          keyboardType: TextInputType.number,
          errorText: state.codeError,
        ),
        const SizedBox(height: 12),
        HigTextField(
          controller: _passwordCtrl,
          label: 'Новый пароль',
          obscureText: true,
          errorText: state.newPasswordError,
        ),
        const SizedBox(height: 16),
        HigButton(
          label: 'Сбросить пароль',
          loading: state.resetSubmitting,
          onPressed: state.resetSubmitting
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  ref.read(forgotPasswordControllerProvider.notifier).reset();
                },
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => ref
              .read(forgotPasswordControllerProvider.notifier)
              .backToRequest(),
          child: const Text('Запросить код заново'),
        ),
      ];
}

