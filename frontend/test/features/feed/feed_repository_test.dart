import 'package:aifb/features/feed/data/data_sources/feed_remote_data_source.dart';
import 'package:aifb/features/feed/data/dto/moment.dart';
import 'package:aifb/features/feed/data/repositories/feed_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements FeedRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late FeedRepositoryImpl repo;

  final tMoment = Moment(
    id: 'm1',
    authorId: 'u1',
    authorName: 'Алия',
    text: 'Привет, семья!',
    createdAt: DateTime.parse('2026-06-14T10:00:00Z'),
    likes: 3,
    likedByMe: false,
  );

  setUp(() {
    remote = _MockRemote();
    repo = FeedRepositoryImpl(remote);
  });

  test('list returns moments from datasource', () async {
    when(() => remote.list()).thenAnswer((_) async => [tMoment]);
    final res = await repo.list();
    expect(res, hasLength(1));
    expect(res.first.authorName, 'Алия');
    expect(res.first.likes, 3);
    expect(res.first.likedByMe, isFalse);
    expect(res.first.createdAt, DateTime.parse('2026-06-14T10:00:00Z'));
    verify(() => remote.list()).called(1);
  });

  test('post forwards text and returns moment', () async {
    when(() => remote.post(any())).thenAnswer((_) async => tMoment);
    final res = await repo.post('Привет, семья!');
    expect(res.id, 'm1');
    verify(() => remote.post('Привет, семья!')).called(1);
  });

  test('delete forwards id', () async {
    when(() => remote.delete(any())).thenAnswer((_) async {});
    await repo.delete('m1');
    verify(() => remote.delete('m1')).called(1);
  });

  test('like forwards id', () async {
    when(() => remote.like(any())).thenAnswer((_) async {});
    await repo.like('m1');
    verify(() => remote.like('m1')).called(1);
  });

  test('unlike forwards id', () async {
    when(() => remote.unlike(any())).thenAnswer((_) async {});
    await repo.unlike('m1');
    verify(() => remote.unlike('m1')).called(1);
  });
}
