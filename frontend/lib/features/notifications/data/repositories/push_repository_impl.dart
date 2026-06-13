import '../../domain/repositories/push_repository.dart';
import '../data_sources/push_remote_data_source.dart';

class PushRepositoryImpl implements PushRepository {
  PushRepositoryImpl(this._remote);
  final PushRemoteDataSource _remote;

  @override
  Future<void> registerToken(String token, String platform) =>
      _remote.registerToken(token, platform);

  @override
  Future<void> deleteToken(String token) => _remote.deleteToken(token);
}
