import 'package:aifb/features/wishlist/data/data_sources/wishlist_remote_data_source.dart';
import 'package:aifb/features/wishlist/data/dto/wishlist_item.dart';
import 'package:aifb/features/wishlist/data/repositories/wishlist_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements WishlistRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late WishlistRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = WishlistRepositoryImpl(remote);
  });

  const item = WishlistItem(
    id: 'w1',
    ownerId: 'u1',
    ownerName: 'Алия',
    title: 'Книга',
    reserved: false,
  );

  test('list returns items from datasource', () async {
    when(() => remote.list()).thenAnswer((_) async => [item]);
    final res = await repo.list();
    expect(res, hasLength(1));
    expect(res.first.title, 'Книга');
    verify(() => remote.list()).called(1);
  });

  test('add forwards title and note and returns item', () async {
    when(() => remote.add(any(), any())).thenAnswer((_) async => item);
    final res = await repo.add('Книга', 'Толстой');
    expect(res.id, 'w1');
    verify(() => remote.add('Книга', 'Толстой')).called(1);
  });

  test('delete forwards id', () async {
    when(() => remote.delete(any())).thenAnswer((_) async {});
    await repo.delete('w1');
    verify(() => remote.delete('w1')).called(1);
  });

  test('reserve forwards id', () async {
    when(() => remote.reserve(any())).thenAnswer((_) async {});
    await repo.reserve('w1');
    verify(() => remote.reserve('w1')).called(1);
  });

  test('unreserve forwards id', () async {
    when(() => remote.unreserve(any())).thenAnswer((_) async {});
    await repo.unreserve('w1');
    verify(() => remote.unreserve('w1')).called(1);
  });
}
