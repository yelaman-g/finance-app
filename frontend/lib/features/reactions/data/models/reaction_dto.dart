/// DTO for a single emoji reaction from the backend.
class ReactionDto {
  const ReactionDto({required this.userId, required this.emoji});

  factory ReactionDto.fromJson(Map<String, dynamic> json) => ReactionDto(
        userId: json['userId'] as String,
        emoji: json['emoji'] as String,
      );

  final String userId;
  final String emoji;
}
