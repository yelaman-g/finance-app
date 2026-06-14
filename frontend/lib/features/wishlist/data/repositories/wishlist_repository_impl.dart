import '../../domain/repositories/wishlist_repository.dart';
import '../data_sources/wishlist_remote_data_source.dart';
import '../dto/wishlist_item.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  WishlistRepositoryImpl(this._remote);
  final WishlistRemoteDataSource _remote;

  @override
  Future<List<WishlistItem>> list() => _remote.list();

  @override
  Future<WishlistItem> add(String title, String? note) =>
      _remote.add(title, note);

  @override
  Future<void> delete(String id) => _remote.delete(id);

  @override
  Future<void> reserve(String id) => _remote.reserve(id);

  @override
  Future<void> unreserve(String id) => _remote.unreserve(id);
}
