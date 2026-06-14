import 'package:aifb/features/capsules/data/data_sources/capsule_remote_data_source.dart';
import 'package:aifb/features/capsules/data/dto/capsule.dart';
import 'package:aifb/features/capsules/data/repositories/capsule_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements CapsuleRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late CapsuleRepositoryImpl repo;

  // Fixtures
  final openDate = DateTime(2030, 6, 1);
  final lockedCapsule = Capsule(
    id: 'c1',
    title: 'Семье через 5 лет',
    openDate: openDate,
    locked: true,
    message: null,
    createdBy: 'u1',
  );
  final openedCapsule = Capsule(
    id: 'c2',
    title: 'Прошлогоднее',
    openDate: DateTime(2020, 1, 1),
    locked: false,
    message: 'Привет из прошлого!',
    createdBy: 'u2',
  );

  setUp(() {
    remote = _MockRemote();
    repo = CapsuleRepositoryImpl(remote);
    registerFallbackValue(DateTime.now());
  });

  test('list forwards call and returns capsules', () async {
    when(() => remote.list())
        .thenAnswer((_) async => [lockedCapsule, openedCapsule]);
    final res = await repo.list();
    expect(res, hasLength(2));
    expect(res.first.title, 'Семье через 5 лет');
    verify(() => remote.list()).called(1);
  });

  test('list returns capsule with locked=true and null message', () async {
    when(() => remote.list()).thenAnswer((_) async => [lockedCapsule]);
    final res = await repo.list();
    final c = res.first;
    expect(c.locked, isTrue);
    expect(c.message, isNull);
  });

  test('list returns capsule with locked=false and revealed message', () async {
    when(() => remote.list()).thenAnswer((_) async => [openedCapsule]);
    final res = await repo.list();
    final c = res.first;
    expect(c.locked, isFalse);
    expect(c.message, 'Привет из прошлого!');
  });

  test('create forwards title, message, date and returns capsule', () async {
    when(() => remote.create(any(), any(), any()))
        .thenAnswer((_) async => lockedCapsule);
    final res = await repo.create('Семье через 5 лет', 'Привет!', openDate);
    expect(res.id, 'c1');
    verify(() => remote.create('Семье через 5 лет', 'Привет!', openDate))
        .called(1);
  });

  test('delete forwards id', () async {
    when(() => remote.delete(any())).thenAnswer((_) async {});
    await repo.delete('c1');
    verify(() => remote.delete('c1')).called(1);
  });
}
