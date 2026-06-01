import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/moments_provider.dart';
import '../widgets/moment_feed_card.dart';
import '../widgets/story_ring.dart';

class MomentsFeedScreen extends ConsumerWidget {
  const MomentsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(momentsFeedNotifierProvider);
    final storiesState = ref.watch(storiesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Moments', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () {
              // Upload new moment
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Stories Section
          SliverToBoxAdapter(
            child: SizedBox(
              height: 120,
              child: storiesState.when(
                data: (stories) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: stories.length + 1, // +1 for "Add Story"
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 35,
                                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                    child: Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        shape: BoxShape.circle,
                                      ),
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: theme.colorScheme.primary,
                                        child: const Icon(Icons.add, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text('Your Story', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: StoryRing(story: stories[index - 1]),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => const SizedBox.shrink(),
              ),
            ),
          ),

          // Divider
          SliverToBoxAdapter(
            child: Divider(color: theme.colorScheme.surfaceContainerHighest, thickness: 1),
          ),

          // Feed Section
          feedState.when(
            data: (moments) {
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => MomentFeedCard(moment: moments[index]),
                  childCount: moments.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, st) => SliverFillRemaining(
              child: Center(child: Text('Error loading feed: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
