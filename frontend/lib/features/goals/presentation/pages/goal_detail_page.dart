import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/goals/presentation/providers/goals_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class GoalDetailPage extends ConsumerWidget {
  const GoalDetailPage({required this.goalId, super.key});
  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(goalContributionsProvider(goalId));
    final fmt = NumberFormat.decimalPattern();
    return Scaffold(
      appBar: AppBar(title: const Text('Цель')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addContribution(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Пополнить'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Взносов пока нет'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final c = items[i];
              return ListTile(
                title: Text('+${fmt.format(c.amount)}'),
                subtitle: Text(
                  '${c.contributedOn.toIso8601String().split('T').first}'
                  '${c.note != null ? ' · ${c.note}' : ''}',
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addContribution(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сумма взноса'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Например, 5000'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              double.tryParse(controller.text.replaceAll(',', '.')),
            ),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    final result = await ref.read(goalsRepositoryProvider).addContribution(
          goalId: goalId,
          amount: amount,
          contributedOn: DateTime.now(),
        );
    if (result is Ok) {
      ref
        ..invalidate(goalContributionsProvider(goalId))
        ..invalidate(goalsProvider);
    }
  }
}
