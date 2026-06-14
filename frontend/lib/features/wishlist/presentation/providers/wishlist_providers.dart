import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/wishlist_remote_data_source.dart';
import '../../data/dto/wishlist_item.dart';
import '../../data/repositories/wishlist_repository_impl.dart';
import '../../domain/repositories/wishlist_repository.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepositoryImpl(
    WishlistRemoteDataSourceImpl(ref.watch(dioProvider)),
  );
});

final wishlistProvider =
    FutureProvider.autoDispose<List<WishlistItem>>((ref) {
  return ref.watch(wishlistRepositoryProvider).list();
});
