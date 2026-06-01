import 'package:flutter/material.dart';
import '../../domain/entities/moment_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StoryRing extends StatelessWidget {
  final Moment story;

  const StoryRing({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        // Open StoryViewerScreen
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: story.isStoryViewed
                  ? null
                  : LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: story.isStoryViewed ? theme.colorScheme.surfaceContainerHighest : null,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surface,
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundImage: NetworkImage(story.authorAvatarUrl),
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scaleXY(begin: 1.0, end: 1.05, duration: 2.seconds, curve: Curves.easeInOut),
          const SizedBox(height: 8),
          Text(
            story.authorName.split(' ').first,
            style: theme.textTheme.bodySmall?.copyWith(
              color: story.isStoryViewed ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
              fontWeight: story.isStoryViewed ? FontWeight.normal : FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
