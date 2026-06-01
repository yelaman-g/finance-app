import 'package:flutter/material.dart';
import '../../domain/entities/insight_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class InsightCard extends StatelessWidget {
  final InsightModel insight;

  const InsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    IconData getIcon() {
      switch (insight.type) {
        case InsightType.warning: return Icons.warning_amber_rounded;
        case InsightType.prediction: return Icons.timeline_rounded;
        case InsightType.achievement: return Icons.emoji_events_rounded;
        case InsightType.recommendation: return Icons.lightbulb_outline_rounded;
      }
    }

    Color getColor() {
      switch (insight.type) {
        case InsightType.warning: return Colors.orangeAccent;
        case InsightType.prediction: return theme.colorScheme.primary;
        case InsightType.achievement: return Colors.amber;
        case InsightType.recommendation: return theme.colorScheme.secondary;
      }
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: getColor().withOpacity(0.3), width: 1.5),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: getColor().withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(getIcon(), color: getColor()),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    insight.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (insight.impactLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      insight.impactLabel!,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              insight.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, duration: 500.ms, curve: Curves.easeOut);
  }
}
