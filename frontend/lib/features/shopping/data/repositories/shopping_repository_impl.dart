import '../../domain/repositories/shopping_repository.dart';
import '../data_sources/shopping_remote_data_source.dart';
import '../dto/shopping_item.dart';

class ShoppingRepositoryImpl implements ShoppingRepository {
  ShoppingRepositoryImpl(this._remote);
  final ShoppingRemoteDataSource _remote;

  @override
  Future<List<ShoppingItem>> list() => _remote.list();

  @override
  Future<ShoppingItem> add(String title) => _remote.add(title);

  @override
  Future<ShoppingItem> toggle(String id) => _remote.toggle(id);

  @override
  Future<void> delete(String id) => _remote.delete(id);
}
