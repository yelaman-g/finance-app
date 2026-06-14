import '../../data/dto/moment.dart';

abstract class FeedRepository {
  Future<List<Moment>> list();
  Future<Moment> post(String text);
  Future<void> delete(String id);
  Future<void> like(String id);
  Future<void> unlike(String id);
}
