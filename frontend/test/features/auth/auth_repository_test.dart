import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/core/storage/secure_storage.dart';
import 'package:aifb/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:aifb/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockStorage extends Mock implements SecureStorage {}

void main() {
  late _MockRemote remote;
  late _MockStorage storage;
  late AuthRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    storage = _MockStorage();
    repo = AuthRepositoryImpl(remote: remote, storage: storage);
  });

  test('forgotPassword returns Ok with devCode', () async {
    when(() => remote.forgotPassword('a@b.com'))
        .thenAnswer((_) async => '123456');
    final result = await repo.forgotPassword(email: 'a@b.com');
    expect(result, isA<Ok<String?>>());
    expect((result as Ok<String?>).value, '123456');
  });

  test('forgotPassword returns Ok with null devCode', () async {
    when(() => remote.forgotPassword('a@b.com')).thenAnswer((_) async => null);
    final result = await repo.forgotPassword(email: 'a@b.com');
    expect((result as Ok<String?>).value, isNull);
  });

  test('resetPassword forwards all fields and returns Ok', () async {
    when(() => remote.resetPassword(
          email: any(named: 'email'),
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) async {});
    final result = await repo.resetPassword(
      email: 'a@b.com',
      code: '123456',
      newPassword: 'newpass123',
    );
    expect(result, isA<Ok<void>>());
    verify(() => remote.resetPassword(
          email: 'a@b.com',
          code: '123456',
          newPassword: 'newpass123',
        )).called(1);
  });
}
