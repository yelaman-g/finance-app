import '../../domain/repositories/poll_repository.dart';
import '../data_sources/poll_remote_data_source.dart';
import '../dto/poll.dart';

class PollRepositoryImpl implements PollRepository {
  PollRepositoryImpl(this._remote);
  final PollRemoteDataSource _remote;

  @override
  Future<List<Poll>> list() => _remote.list();

  @override
  Future<Poll> create(String question, List<String> options) =>
      _remote.create(question, options);

  @override
  Future<void> vote(String pollId, String optionId) =>
      _remote.vote(pollId, optionId);

  @override
  Future<void> close(String pollId) => _remote.close(pollId);
}
