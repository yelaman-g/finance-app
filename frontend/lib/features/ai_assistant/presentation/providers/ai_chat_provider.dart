import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/ai_message.dart';
import 'ai_dependency_provider.dart';

part 'ai_chat_provider.g.dart';

@riverpod
class AiChatNotifier extends _$AiChatNotifier {
  @override
  FutureOr<List<AiMessage>> build() async {
    return [
      AiMessage(
        id: 'welcome',
        content: 'Здравствуйте! Я ваш ИИ-помощник по финансам. Спросите про бюджет, расходы или накопления.',
        role: MessageRole.ai,
        timestamp: DateTime.now(),
      ),
    ];
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
      final response = await repo.sendMessage(text, previousState);
      
      // Remove typing indicator and add real response
      final currentList = (state.valueOrNull ?? <AiMessage>[])
          .where((msg) => !msg.isTyping)
          .toList();
      state = AsyncData([...currentList, response]);
    } catch (e, st) {
      // Show error (typing indicator is discarded with the previous state)
      state = AsyncError(e, st);
    }
  }
}
