import 'package:aifb/app/router/routes.dart';
import 'package:aifb/features/goals/presentation/providers/goals_providers.dart';
import 'package:aifb/features/goals/presentation/widgets/goal_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(goalsProvider);
    final fmt = NumberFormat.decimalPattern();
    return Scaffold(
      appBar: AppBar(title: const Text('Цели')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showGoalForm(context);
          if (created ?? false) ref.invalidate(goalsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Новая цель'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(goalsProvider.future),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 80),
              Center(child: Text('Ошибка: $e')),
            ],
          ),
          data: (goals) {
            if (goals.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Целей пока нет')),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: goals.length,
              itemBuilder: (_, i) {
                final g = goals[i];
                return Card(
                  child: ListTile(
                    title: Text(g.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: (g.percentage / 100).clamp(0, 1).toDouble(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${fmt.format(g.savedAmount)} / '
                          '${fmt.format(g.targetAmount)} · ${g.status}',
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.push('${AppRoutes.goals.path}/${g.id}'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
