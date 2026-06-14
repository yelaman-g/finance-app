import '../../domain/repositories/capsule_repository.dart';
import '../data_sources/capsule_remote_data_source.dart';
import '../dto/capsule.dart';

class CapsuleRepositoryImpl implements CapsuleRepository {
  CapsuleRepositoryImpl(this._remote);
  final CapsuleRemoteDataSource _remote;

  @override
  Future<List<Capsule>> list() => _remote.list();

  @override
  Future<Capsule> create(String title, String message, DateTime openDate) =>
      _remote.create(title, message, openDate);

  @override
  Future<void> delete(String id) => _remote.delete(id);
}
