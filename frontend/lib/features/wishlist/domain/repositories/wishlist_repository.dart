import '../../data/dto/wishlist_item.dart';

abstract class WishlistRepository {
  Future<List<WishlistItem>> list();
  Future<WishlistItem> add(String title, String? note);
  Future<void> delete(String id);
  Future<void> reserve(String id);
  Future<void> unreserve(String id);
}
