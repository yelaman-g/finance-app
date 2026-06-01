import '../../domain/entities/moment_model.dart';

abstract class MomentsRemoteDataSource {
  Future<List<Moment>> getFeed();
  Future<List<Moment>> getStories();
  Future<void> reactToMoment(String momentId, String emoji);
  Future<void> addComment(String momentId, String text);
}

class MomentsRemoteDataSourceImpl implements MomentsRemoteDataSource {
  final List<Moment> _mockMoments = [
    Moment(
      id: '1',
      authorName: 'Sarah Jenkins',
      authorAvatarUrl: 'https://i.pravatar.cc/150?u=sarah',
      type: MomentType.achievement,
      achievementTitle: 'Saved \$500 this month! 🚀',
      aiCaption: 'Sarah hit her monthly savings goal early. Great financial discipline!',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      reactions: [const Reaction(emoji: '🔥', count: 12), const Reaction(emoji: '👏', count: 5)],
      comments: [
        Comment(
          id: 'c1',
          authorName: 'Mike',
          authorAvatarUrl: 'https://i.pravatar.cc/150?u=mike',
          text: 'Awesome job!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        )
      ],
    ),
    Moment(
      id: '2',
      authorName: 'Family Vacation Fund',
      authorAvatarUrl: 'https://i.pravatar.cc/150?u=vacation',
      type: MomentType.photo,
      photoUrl: 'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?w=800&q=80',
      aiCaption: 'We finally booked the beach house for summer! Thanks to our shared family budget.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      reactions: [const Reaction(emoji: '❤️', count: 24, userReacted: true)],
    ),
  ];

  @override
  Future<List<Moment>> getFeed() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return _mockMoments;
  }

  @override
  Future<List<Moment>> getStories() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return _mockMoments.where((m) => m.photoUrl != null).toList();
  }

  @override
  Future<void> reactToMoment(String momentId, String emoji) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> addComment(String momentId, String text) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
}
