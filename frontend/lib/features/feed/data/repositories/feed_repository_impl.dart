import '../../domain/repositories/feed_repository.dart';
import '../data_sources/feed_remote_data_source.dart';
import '../dto/moment.dart';

class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl(this._remote);
  final FeedRemoteDataSource _remote;

  @override
  Future<List<Moment>> list() => _remote.list();

  @override
  Future<Moment> post(String text) => _remote.post(text);

  @override
  Future<void> delete(String id) => _remote.delete(id);

  @override
  Future<void> like(String id) => _remote.like(id);

  @override
  Future<void> unlike(String id) => _remote.unlike(id);
}
