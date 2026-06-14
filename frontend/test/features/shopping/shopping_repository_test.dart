import 'package:aifb/features/shopping/data/data_sources/shopping_remote_data_source.dart';
import 'package:aifb/features/shopping/data/dto/shopping_item.dart';
import 'package:aifb/features/shopping/data/repositories/shopping_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements ShoppingRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late ShoppingRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = ShoppingRepositoryImpl(remote);
  });

  // Item fixture
  const item = ShoppingItem(
    id: 's1',
    title: 'Молоко',
    checked: false,
    createdBy: 'u1',
  );

  test('list returns items from datasource', () async {
    when(() => remote.list()).thenAnswer((_) async => [item]);
    final res = await repo.list();
    expect(res, hasLength(1));
    expect(res.first.title, 'Молоко');
    verify(() => remote.list()).called(1);
  });

  test('add forwards title and returns item', () async {
    when(() => remote.add(any())).thenAnswer((_) async => item);
    final res = await repo.add('Молоко');
    expect(res.id, 's1');
    verify(() => remote.add('Молоко')).called(1);
  });

  test('toggle forwards id and returns toggled item', () async {
    const toggled = ShoppingItem(id: 's1', title: 'Молоко', checked: true, createdBy: 'u1');
    when(() => remote.toggle(any())).thenAnswer((_) async => toggled);
    final res = await repo.toggle('s1');
    expect(res.checked, isTrue);
    verify(() => remote.toggle('s1')).called(1);
  });

  test('delete forwards id', () async {
    when(() => remote.delete(any())).thenAnswer((_) async {});
    await repo.delete('s1');
    verify(() => remote.delete('s1')).called(1);
  });
}
