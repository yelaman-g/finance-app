import 'package:aifb/core/network/api_endpoints.dart';
import 'package:aifb/core/network/envelope.dart';
import 'package:aifb/features/chat/data/dto/chat_message.dart';
import 'package:dio/dio.dart';

abstract class ChatRemoteDataSource {
  Future<List<ChatMessage>> history();
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  ChatRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<ChatMessage>> history() async {
    final res =
        await _dio.get<Map<String, dynamic>>(ApiEndpoints.chat);
    final list = unwrapList(res.data);
    return list
        .cast<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList();
  }
}
