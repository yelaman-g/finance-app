import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/moment_model.dart';
import '../../data/data_sources/moments_remote_data_source.dart';
import '../../data/repositories/moments_repository_impl.dart';

part 'moments_provider.g.dart';

@riverpod
MomentsRepositoryImpl momentsRepository(MomentsRepositoryRef ref) {
  return MomentsRepositoryImpl(MomentsRemoteDataSourceImpl());
}

@riverpod
class MomentsFeedNotifier extends _$MomentsFeedNotifier {
  @override
  FutureOr<List<Moment>> build() async {
    return ref.watch(momentsRepositoryProvider).getFeed();
  }

  Future<void> react(String momentId, String emoji) async {
    final repo = ref.read(momentsRepositoryProvider);
    
    // Optimistic update
    final currentList = state.valueOrNull ?? [];
    final newList = currentList.map((m) {
      if (m.id == momentId) {
        final existingReactions = List<Reaction>.from(m.reactions);
        final index = existingReactions.indexWhere((r) => r.emoji == emoji);
        if (index != -1) {
          final r = existingReactions[index];
          existingReactions[index] = r.copyWith(
            count: r.userReacted ? r.count - 1 : r.count + 1,
            userReacted: !r.userReacted,
          );
        } else {
          existingReactions.add(Reaction(emoji: emoji, count: 1, userReacted: true));
        }
        return m.copyWith(reactions: existingReactions);
      }
      return m;
    }).toList();
    
    state = AsyncData(newList);
    await repo.reactToMoment(momentId, emoji);
  }
}

@riverpod
Future<List<Moment>> stories(StoriesRef ref) {
  return ref.watch(momentsRepositoryProvider).getStories();
}
