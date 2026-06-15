import 'package:aifb/core/errors/error_text.dart';
import 'package:aifb/features/ai_assistant/presentation/providers/ai_extra_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetAnalysisTab extends ConsumerWidget {
  const BudgetAnalysisTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(budgetAnalysisProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(budgetAnalysisProvider.future),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          children: [
            const SizedBox(height: 80),
            Center(child: Text('Не удалось получить анализ. ${errorText(e)}')),
          ],
        ),
        data: (a) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Анализ бюджета', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(a.analysis),
            const SizedBox(height: 20),
            if (a.tips.isNotEmpty) ...[
              Text('Советы', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...a.tips.map(
                (t) => ListTile(
                  leading: const Icon(Icons.lightbulb_outline),
                  title: Text(t),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
