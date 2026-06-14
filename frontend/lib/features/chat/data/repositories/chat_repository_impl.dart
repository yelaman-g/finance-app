import 'package:aifb/core/errors/error_mapper.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/chat/data/data_sources/chat_remote_data_source.dart';
import 'package:aifb/features/chat/data/dto/chat_message.dart';
import 'package:aifb/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._ds);
  final ChatRemoteDataSource _ds;

  @override
  Future<List<ChatMessage>> history() => _ds.history();

  /// Wraps [history] in a [Result] for callers that need explicit error
  /// handling (e.g. providers).
  Future<Result<List<ChatMessage>>> historyResult() async {
    try {
      return Result.ok(await _ds.history());
    } catch (e) {
      return Result.err(mapDioError(e));
    }
  }
}
