class Moment {
  const Moment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
    required this.likes,
    required this.likedByMe,
  });

  factory Moment.fromJson(Map<String, dynamic> j) => Moment(
        id: j['id'] as String? ?? '',
        authorId: j['authorId'] as String? ?? '',
        authorName: j['authorName'] as String? ?? '',
        text: j['text'] as String? ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String),
        likes: j['likes'] as int? ?? 0,
        likedByMe: j['likedByMe'] as bool? ?? false,
      );

  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;
  final int likes;
  final bool likedByMe;
}
