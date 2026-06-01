// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReactionImpl _$$ReactionImplFromJson(Map<String, dynamic> json) =>
    _$ReactionImpl(
      emoji: json['emoji'] as String,
      count: (json['count'] as num).toInt(),
      userReacted: json['userReacted'] as bool? ?? false,
    );

Map<String, dynamic> _$$ReactionImplToJson(_$ReactionImpl instance) =>
    <String, dynamic>{
      'emoji': instance.emoji,
      'count': instance.count,
      'userReacted': instance.userReacted,
    };

_$CommentImpl _$$CommentImplFromJson(Map<String, dynamic> json) =>
    _$CommentImpl(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      authorAvatarUrl: json['authorAvatarUrl'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$$CommentImplToJson(_$CommentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'authorName': instance.authorName,
      'authorAvatarUrl': instance.authorAvatarUrl,
      'text': instance.text,
      'timestamp': instance.timestamp.toIso8601String(),
    };

_$MomentImpl _$$MomentImplFromJson(Map<String, dynamic> json) => _$MomentImpl(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      authorAvatarUrl: json['authorAvatarUrl'] as String,
      type: $enumDecode(_$MomentTypeEnumMap, json['type']),
      photoUrl: json['photoUrl'] as String?,
      aiCaption: json['aiCaption'] as String?,
      achievementTitle: json['achievementTitle'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      reactions: (json['reactions'] as List<dynamic>?)
              ?.map((e) => Reaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      comments: (json['comments'] as List<dynamic>?)
              ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isStoryViewed: json['isStoryViewed'] as bool? ?? false,
    );

Map<String, dynamic> _$$MomentImplToJson(_$MomentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'authorName': instance.authorName,
      'authorAvatarUrl': instance.authorAvatarUrl,
      'type': _$MomentTypeEnumMap[instance.type]!,
      'photoUrl': instance.photoUrl,
      'aiCaption': instance.aiCaption,
      'achievementTitle': instance.achievementTitle,
      'timestamp': instance.timestamp.toIso8601String(),
      'reactions': instance.reactions,
      'comments': instance.comments,
      'isStoryViewed': instance.isStoryViewed,
    };

const _$MomentTypeEnumMap = {
  MomentType.photo: 'photo',
  MomentType.achievement: 'achievement',
  MomentType.milestone: 'milestone',
};
