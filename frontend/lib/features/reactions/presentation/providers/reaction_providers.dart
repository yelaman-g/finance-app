import 'package:aifb/core/errors/failure_message.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/core/network/dio_client.dart';
import 'package:aifb/features/reactions/data/models/reaction_dto.dart';
import 'package:aifb/features/reactions/data/reaction_remote_data_source.dart';
import 'package:aifb/features/reactions/data/reaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reactionDataSourceProvider = Provider<ReactionRemoteDataSource>((ref) {
  return ReactionRemoteDataSource(ref.watch(dioProvider));
});

final reactionRepositoryProvider = Provider<ReactionRepository>((ref) {
  return ReactionRepository(ref.watch(reactionDataSourceProvider));
});

/// Batch-fetches reactions for a list of transaction ids.
/// Keyed by the sorted, joined ids so invalidation works correctly.
final reactionsForProvider = FutureProvider.autoDispose
    .family<Map<String, List<ReactionDto>>, List<String>>(
  (ref, txIds) async {
    if (txIds.isEmpty) return {};
    final result =
        await ref.watch(reactionRepositoryProvider).reactionsFor(txIds);
    return switch (result) {
      Ok<Map<String, List<ReactionDto>>>(value: final v) => v,
      Err<Map<String, List<ReactionDto>>>(failure: final f) =>
        throw Exception(f.userMessage),
    };
  },
);
