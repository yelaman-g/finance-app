import '../../data/dto/shopping_item.dart';

abstract class ShoppingRepository {
  Future<List<ShoppingItem>> list();
  Future<ShoppingItem> add(String title);
  Future<ShoppingItem> toggle(String id);
  Future<void> delete(String id);
}
