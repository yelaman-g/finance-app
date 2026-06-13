import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/ai_chat_provider.dart';
import '../providers/ai_insights_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/insight_card.dart';
import '../widgets/typing_indicator.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isNotEmpty) {
      ref.read(aiChatNotifierProvider.notifier).sendMessage(text);
      _textController.clear();
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatNotifierProvider);
    final insightsState = ref.watch(aiInsightsNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // Insights Section
          insightsState.when(
            data: (insights) {
              if (insights.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: insights.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: InsightCard(insight: insights[index]),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
            error: (err, st) => const SizedBox.shrink(),
          ),

          // Chat Section
          Expanded(
            child: chatState.when(
              data: (messages) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    if (msg.isTyping) {
                      return const Padding(
                        padding: EdgeInsets.only(left: 16, bottom: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TypingIndicator(),
                        ),
                      ).animate().fadeIn();
                    }
                    return ChatBubble(message: msg)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOut);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error loading chat: $err')),
            ),
          ),

          // Input Section
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Ask about your finances...',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
