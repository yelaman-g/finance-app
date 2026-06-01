import 'package:freezed_annotation/freezed_annotation.dart';

part 'moment_model.freezed.dart';
part 'moment_model.g.dart';

enum MomentType { photo, achievement, milestone }

@freezed
class Reaction with _$Reaction {
  const factory Reaction({
    required String emoji,
    required int count,
    @Default(false) bool userReacted,
  }) = _Reaction;

  factory Reaction.fromJson(Map<String, dynamic> json) => _$ReactionFromJson(json);
}

@freezed
class Comment with _$Comment {
  const factory Comment({
    required String id,
    required String authorName,
    required String authorAvatarUrl,
    required String text,
    required DateTime timestamp,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
}

@freezed
class Moment with _$Moment {
  const factory Moment({
    required String id,
    required String authorName,
    required String authorAvatarUrl,
    required MomentType type,
    String? photoUrl,
    String? aiCaption,
    String? achievementTitle,
    required DateTime timestamp,
    @Default([]) List<Reaction> reactions,
    @Default([]) List<Comment> comments,
    @Default(false) bool isStoryViewed,
  }) = _Moment;

  factory Moment.fromJson(Map<String, dynamic> json) => _$MomentFromJson(json);
}
