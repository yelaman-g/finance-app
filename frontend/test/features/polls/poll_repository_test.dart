import 'package:aifb/features/polls/data/data_sources/poll_remote_data_source.dart';
import 'package:aifb/features/polls/data/dto/poll.dart';
import 'package:aifb/features/polls/data/repositories/poll_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements PollRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late PollRepositoryImpl repo;

  // Fixtures
  const optionA = PollOption(id: 'o1', text: 'Да', votes: 3);
  const optionB = PollOption(id: 'o2', text: 'Нет', votes: 1);
  const poll = Poll(
    id: 'p1',
    question: 'Поедем на море?',
    closed: false,
    createdBy: 'u1',
    options: [optionA, optionB],
    myVoteOptionId: 'o1',
  );

  setUp(() {
    remote = _MockRemote();
    repo = PollRepositoryImpl(remote);
  });

  test('list forwards call and returns polls', () async {
    when(() => remote.list()).thenAnswer((_) async => [poll]);
    final res = await repo.list();
    expect(res, hasLength(1));
    expect(res.first.question, 'Поедем на море?');
    verify(() => remote.list()).called(1);
  });

  test('list parses options and myVoteOptionId', () async {
    when(() => remote.list()).thenAnswer((_) async => [poll]);
    final res = await repo.list();
    final p = res.first;
    expect(p.options, hasLength(2));
    expect(p.options.first.id, 'o1');
    expect(p.options.first.votes, 3);
    expect(p.myVoteOptionId, 'o1');
  });

  test('create forwards question and options', () async {
    when(() => remote.create(any(), any())).thenAnswer((_) async => poll);
    final res = await repo.create('Поедем на море?', ['Да', 'Нет']);
    expect(res.id, 'p1');
    verify(() => remote.create('Поедем на море?', ['Да', 'Нет'])).called(1);
  });

  test('vote forwards pollId and optionId', () async {
    when(() => remote.vote(any(), any())).thenAnswer((_) async {});
    await repo.vote('p1', 'o1');
    verify(() => remote.vote('p1', 'o1')).called(1);
  });

  test('close forwards pollId', () async {
    when(() => remote.close(any())).thenAnswer((_) async {});
    await repo.close('p1');
    verify(() => remote.close('p1')).called(1);
  });
}
