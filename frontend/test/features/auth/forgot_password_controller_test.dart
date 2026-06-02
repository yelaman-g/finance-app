import 'package:aifb/core/errors/failure.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/auth/domain/repositories/auth_repository.dart';
import 'package:aifb/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:aifb/features/auth/presentation/providers/auth_providers.dart';
import 'package:aifb/features/auth/presentation/state/forgot_password_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockAuthRepo();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  ForgotPasswordController ctrl() =>
      container.read(forgotPasswordControllerProvider.notifier);
  ForgotPasswordState state() =>
      container.read(forgotPasswordControllerProvider);

  test('requestCode with devCode moves to reset step', () async {
    when(() => repo.forgotPassword(email: any(named: 'email')))
        .thenAnswer((_) async => const Result.ok('123456'));
    ctrl().emailChanged('a@b.com');
    await ctrl().requestCode();
    expect(state().step, ForgotStep.reset);
    expect(state().devCode, '123456');
  });

  test('requestCode with null devCode still moves to reset step', () async {
    when(() => repo.forgotPassword(email: any(named: 'email')))
        .thenAnswer((_) async => const Result<String?>.ok(null));
    ctrl().emailChanged('a@b.com');
    await ctrl().requestCode();
    expect(state().step, ForgotStep.reset);
    expect(state().devCode, isNull);
  });

  test('requestCode with invalid email does not call repo', () async {
    ctrl().emailChanged('not-an-email');
    await ctrl().requestCode();
    expect(state().emailError, isNotNull);
    expect(state().step, ForgotStep.request);
    verifyNever(() => repo.forgotPassword(email: any(named: 'email')));
  });

  test('reset success sets resetDone', () async {
    when(() => repo.resetPassword(
          email: any(named: 'email'),
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) async => const Result<void>.ok(null));
    ctrl()
      ..emailChanged('a@b.com')
      ..codeChanged('123456')
      ..newPasswordChanged('secret123');
    await ctrl().reset();
    expect(state().resetDone, isTrue);
  });

  test('reset failure sets failure and not done', () async {
    when(() => repo.resetPassword(
          email: any(named: 'email'),
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer(
      (_) async => const Result<void>.err(Failure.validation(message: 'bad')),
    );
    ctrl()
      ..emailChanged('a@b.com')
      ..codeChanged('123456')
      ..newPasswordChanged('secret123');
    await ctrl().reset();
    expect(state().resetDone, isFalse);
    expect(state().failure, isNotNull);
  });

  test('reset with invalid code does not call repo', () async {
    ctrl()
      ..emailChanged('a@b.com')
      ..codeChanged('12')
      ..newPasswordChanged('secret123');
    await ctrl().reset();
    expect(state().codeError, isNotNull);
    verifyNever(() => repo.resetPassword(
          email: any(named: 'email'),
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        ));
  });
}
