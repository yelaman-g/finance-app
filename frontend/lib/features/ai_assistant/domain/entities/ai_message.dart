enum MessageRole { user, ai, system }

class AiMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isTyping;
  final List<String>? suggestedActions;

  const AiMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isTyping = false,
    this.suggestedActions,
  });

  AiMessage copyWith({
    String? id,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    bool? isTyping,
    List<String>? suggestedActions,
  }) {
    return AiMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      isTyping: isTyping ?? this.isTyping,
      suggestedActions: suggestedActions ?? this.suggestedActions,
    );
  }
}
