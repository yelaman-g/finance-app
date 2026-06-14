import 'package:aifb/features/chat/data/dto/chat_message.dart';

abstract class ChatRepository {
  Future<List<ChatMessage>> history();
}
