import 'package:aifb/features/notifications/application/push_service.dart';
import 'package:aifb/features/notifications/domain/repositories/push_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements PushRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('enable registers a dev token in dev mode', () async {
    final repo = _MockRepo();
    when(() => repo.registerToken(any(), any())).thenAnswer((_) async {});
    final service = PushService(repo);

    await service.enable();

    // FCM_DEV_MODE отсутствует в тестовом окружении (dotenv не загружен) → devMode=true,
    // токен синтетический "dev-...-token".
    verify(() => repo.registerToken(
        any(that: startsWith('dev-')), any())).called(1);
  });

  test('disable deletes the dev token in dev mode', () async {
    final repo = _MockRepo();
    when(() => repo.deleteToken(any())).thenAnswer((_) async {});
    final service = PushService(repo);

    await service.disable();

    verify(() => repo.deleteToken(any(that: startsWith('dev-')))).called(1);
  });
}
