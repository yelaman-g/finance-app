import '../../domain/entities/moment_model.dart';
import '../data_sources/moments_remote_data_source.dart';

class MomentsRepositoryImpl {
  final MomentsRemoteDataSource _remoteDataSource;

  MomentsRepositoryImpl(this._remoteDataSource);

  Future<List<Moment>> getFeed() => _remoteDataSource.getFeed();
  
  Future<List<Moment>> getStories() => _remoteDataSource.getStories();
  
  Future<void> reactToMoment(String momentId, String emoji) => _remoteDataSource.reactToMoment(momentId, emoji);
  
  Future<void> addComment(String momentId, String text) => _remoteDataSource.addComment(momentId, text);
}
