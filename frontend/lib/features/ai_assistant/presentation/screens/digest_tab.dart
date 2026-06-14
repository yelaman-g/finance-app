import 'package:aifb/features/ai_assistant/presentation/providers/ai_extra_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DigestTab extends ConsumerWidget {
  const DigestTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(digestProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(digestProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          children: [
            const SizedBox(height: 80),
            Center(child: Text('Не удалось загрузить дайджест: $e')),
          ],
        ),
        data: (digest) {
          final dateFormat = DateFormat('d MMM', 'ru');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Совет дня
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tips_and_updates_outlined),
                          const SizedBox(width: 8),
                          Text(
                            'Совет дня',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(digest.tipOfDay),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Итоги недели
              Text('Итоги недели', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(digest.narrative),
              const SizedBox(height: 16),
              // Основные события
              if (digest.highlights.isNotEmpty) ...[
                Text('Основные события', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...digest.highlights.map(
                  (h) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(h)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Ближайшие события
              if (digest.upcomingEvents.isNotEmpty) ...[
                Text('Ближайшие события', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...digest.upcomingEvents.map(
                  (e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(e.title),
                    trailing: Text(
                      dateFormat.format(e.date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
