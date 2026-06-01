import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/ai_message.dart';
import 'ai_dependency_provider.dart';

part 'ai_chat_provider.g.dart';

@riverpod
class AiChatNotifier extends _$AiChatNotifier {
  @override
  FutureOr<List<AiMessage>> build() async {
    final repo = ref.watch(aiAssistantRepositoryProvider);
    return repo.getChatHistory();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    final repo = ref.read(aiAssistantRepositoryProvider);
    
    final userMessage = AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    // Optimistic UI update + add typing indicator
    final previousState = state.valueOrNull ?? [];
    
    final typingMessage = AiMessage(
      id: 'typing_indicator',
      content: '',
      role: MessageRole.ai,
      timestamp: DateTime.now(),
      isTyping: true,
    );

    state = AsyncData([...previousState, userMessage, typingMessage]);

    try {
      final response = await repo.sendMessage(text);
      
      // Remove typing indicator and add real response
      final currentList = state.valueOrNull ?? [];
      currentList.removeWhere((msg) => msg.isTyping);
      state = AsyncData([...currentList, response]);
    } catch (e, st) {
      // Revert or show error
      final currentList = state.valueOrNull ?? [];
      currentList.removeWhere((msg) => msg.isTyping);
      state = AsyncError(e, st);
    }
  }
}
