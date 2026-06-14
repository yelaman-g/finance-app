import '../../data/dto/poll.dart';

abstract class PollRepository {
  Future<List<Poll>> list();
  Future<Poll> create(String question, List<String> options);
  Future<void> vote(String pollId, String optionId);
  Future<void> close(String pollId);
}
