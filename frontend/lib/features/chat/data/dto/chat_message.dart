/// A single chat message as returned by the backend.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ChatMessage && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
