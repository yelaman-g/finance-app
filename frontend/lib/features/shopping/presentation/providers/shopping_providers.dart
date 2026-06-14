import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/shopping_remote_data_source.dart';
import '../../data/dto/shopping_item.dart';
import '../../data/repositories/shopping_repository_impl.dart';
import '../../domain/repositories/shopping_repository.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepositoryImpl(
    ShoppingRemoteDataSourceImpl(ref.watch(dioProvider)),
  );
});

final shoppingListProvider =
    FutureProvider.autoDispose<List<ShoppingItem>>((ref) {
  return ref.watch(shoppingRepositoryProvider).list();
});
