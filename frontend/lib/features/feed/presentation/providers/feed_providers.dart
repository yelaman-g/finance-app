import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/feed_remote_data_source.dart';
import '../../data/dto/moment.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/repositories/feed_repository.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepositoryImpl(
    FeedRemoteDataSourceImpl(ref.watch(dioProvider)),
  );
});

final feedProvider = FutureProvider.autoDispose<List<Moment>>((ref) {
  return ref.watch(feedRepositoryProvider).list();
});
