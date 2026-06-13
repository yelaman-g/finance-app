import 'package:aifb/features/notifications/data/data_sources/push_remote_data_source.dart';
import 'package:aifb/features/notifications/data/repositories/push_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements PushRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late PushRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = PushRepositoryImpl(remote);
  });

  test('registerToken forwards token+platform', () async {
    when(() => remote.registerToken(any(), any())).thenAnswer((_) async {});
    await repo.registerToken('tok-1', 'ANDROID');
    verify(() => remote.registerToken('tok-1', 'ANDROID')).called(1);
  });

  test('deleteToken forwards token', () async {
    when(() => remote.deleteToken(any())).thenAnswer((_) async {});
    await repo.deleteToken('tok-1');
    verify(() => remote.deleteToken('tok-1')).called(1);
  });
}
