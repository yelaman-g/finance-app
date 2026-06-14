import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/poll_remote_data_source.dart';
import '../../data/dto/poll.dart';
import '../../data/repositories/poll_repository_impl.dart';
import '../../domain/repositories/poll_repository.dart';

final pollRepositoryProvider = Provider<PollRepository>((ref) {
  return PollRepositoryImpl(
    PollRemoteDataSourceImpl(ref.watch(dioProvider)),
  );
});

final pollsProvider = FutureProvider.autoDispose<List<Poll>>((ref) {
  return ref.watch(pollRepositoryProvider).list();
});
