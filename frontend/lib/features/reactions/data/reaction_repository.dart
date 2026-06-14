import 'package:aifb/core/errors/error_mapper.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/reactions/data/models/reaction_dto.dart';
import 'package:aifb/features/reactions/data/reaction_remote_data_source.dart';

/// Repository for emoji reactions. Wraps [ReactionRemoteDataSource] with
/// error handling via [Result].
class ReactionRepository {
  ReactionRepository(this._ds);
  final ReactionRemoteDataSource _ds;

  Future<Result<void>> react(String txId, String emoji) =>
      _guard(() => _ds.react(txId, emoji));

  Future<Result<void>> removeReaction(String txId) =>
      _guard(() => _ds.removeReaction(txId));

  Future<Result<Map<String, List<ReactionDto>>>> reactionsFor(
    List<String> txIds,
  ) =>
      _guard(() => _ds.reactionsFor(txIds));

  Future<Result<T>> _guard<T>(Future<T> Function() task) async {
    try {
      return Result.ok(await task());
    } catch (e) {
      return Result.err(mapDioError(e));
    }
  }
}
