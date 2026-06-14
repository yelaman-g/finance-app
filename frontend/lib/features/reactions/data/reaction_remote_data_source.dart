import 'package:aifb/core/network/api_endpoints.dart';
import 'package:aifb/features/reactions/data/models/reaction_dto.dart';
import 'package:dio/dio.dart';

/// Raw HTTP transport for reactions endpoints.
class ReactionRemoteDataSource {
  ReactionRemoteDataSource(this._dio);
  final Dio _dio;

  Future<void> react(String txId, String emoji) async {
    await _dio.post<void>(
      '${ApiEndpoints.transactions}/$txId/reactions',
      data: {'emoji': emoji},
    );
  }

  Future<void> removeReaction(String txId) async {
    await _dio.delete<void>('${ApiEndpoints.transactions}/$txId/reactions');
  }

  /// Batch-fetches reactions for a list of transaction ids.
  /// Returns map of txId → list of [ReactionDto].
  Future<Map<String, List<ReactionDto>>> reactionsFor(
    List<String> txIds,
  ) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '${ApiEndpoints.transactions}/reactions',
      queryParameters: {'transactionIds': txIds.join(',')},
    );
    final body = res.data;
    final data = body?['data'];
    if (data is! Map) return {};
    return data.map(
      (key, value) => MapEntry(
        key as String,
        (value as List)
            .map((e) => ReactionDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }
}
