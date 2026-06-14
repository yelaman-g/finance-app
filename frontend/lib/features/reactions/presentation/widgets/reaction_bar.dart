import 'package:aifb/features/reactions/data/models/reaction_dto.dart';
import 'package:aifb/features/reactions/presentation/providers/reaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The fixed set of supported emoji reactions.
const kReactionEmojis = ['😅', '👍', '❤️', '😮', '🎉'];

/// Displays grouped emoji reaction chips and an "add" button for a single
/// family transaction. Handles react / remove via the repository.
class ReactionBar extends ConsumerWidget {
  const ReactionBar({
    required this.txId,
    required this.currentUserId,
    required this.txIds,
    super.key,
  });

  /// The transaction this bar belongs to.
  final String txId;

  /// The logged-in user's id, used to detect own reaction.
  final String currentUserId;

  /// Full list of transaction ids shown on screen (for the batch provider).
  final List<String> txIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reactionsForProvider(txIds));

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (all) {
        final reactions = all[txId] ?? [];
        return _ReactionBarContent(
          txId: txId,
          currentUserId: currentUserId,
          reactions: reactions,
          txIds: txIds,
        );
      },
    );
  }
}

class _ReactionBarContent extends ConsumerWidget {
  const _ReactionBarContent({
    required this.txId,
    required this.currentUserId,
    required this.reactions,
    required this.txIds,
  });

  final String txId;
  final String currentUserId;
  final List<ReactionDto> reactions;
  final List<String> txIds;

  /// Groups reactions by emoji and returns counts.
  Map<String, int> get _counts {
    final map = <String, int>{};
    for (final r in reactions) {
      map[r.emoji] = (map[r.emoji] ?? 0) + 1;
    }
    return map;
  }

  String? get _myEmoji {
    for (final r in reactions) {
      if (r.userId == currentUserId) return r.emoji;
    }
    return null;
  }

  Future<void> _onEmojiSelected(
    BuildContext context,
    WidgetRef ref,
    String emoji,
  ) async {
    final repo = ref.read(reactionRepositoryProvider);
    final myEmoji = _myEmoji;
    if (myEmoji == emoji) {
      // Toggle off: remove own reaction.
      await repo.removeReaction(txId);
    } else {
      // Upsert: backend handles replacing existing reaction.
      await repo.react(txId, emoji);
    }
    ref.invalidate(reactionsForProvider(txIds));
  }

  void _showPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: kReactionEmojis
                .map(
                  (e) => GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _onEmojiSelected(context, ref, e);
                    },
                    child: Text(e, style: const TextStyle(fontSize: 28)),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = _counts;
    final myEmoji = _myEmoji;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8, bottom: 6),
      child: Row(
        children: [
          Wrap(
            spacing: 4,
            children: counts.entries.map((entry) {
              final isOwn = entry.key == myEmoji;
              return GestureDetector(
                onTap: () => _onEmojiSelected(context, ref, entry.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isOwn
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: isOwn
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                  child: Text(
                    '${entry.key} ${entry.value}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 28,
            height: 28,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 18,
              icon: const Icon(Icons.add_reaction_outlined),
              tooltip: 'Добавить реакцию',
              onPressed: () => _showPicker(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}
