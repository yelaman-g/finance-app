import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/goals/data/models/goal_model.dart';
import 'package:aifb/features/goals/presentation/providers/goals_providers.dart';
import 'package:aifb/features/goals/presentation/widgets/goal_form_sheet.dart';
import 'package:aifb/shared/widgets/inset_section.dart';
import 'package:aifb/shared/widgets/large_title_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class GoalDetailPage extends ConsumerWidget {
  const GoalDetailPage({required this.goalId, super.key});
  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hig = HigColors.of(context);
    final async = ref.watch(goalContributionsProvider(goalId));
    final fmt = NumberFormat.decimalPattern();

    return LargeTitleScaffold(
      title: 'Цель',
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () async {
            final res = await ref.read(goalsRepositoryProvider).get(goalId);
            if (res is Ok<GoalModel> && context.mounted) {
              final changed = await showGoalForm(context, existing: res.value);
              if (changed ?? false) {
                ref
                  ..invalidate(goalContributionsProvider(goalId))
                  ..invalidate(goalsProvider(Scope.personal));
              }
            }
          },
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addContribution(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Пополнить'),
      ),
      slivers: [
        async.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Ошибка: $e')),
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Text(
                    'Взносов пока нет',
                    style: TextStyle(color: hig.secondaryLabel),
                  ),
                ),
              );
            }
            return InsetSection(
              header: 'Взносы',
              children: items.map((c) {
                final dateStr =
                    c.contributedOn.toIso8601String().split('T').first;
                final subtitle =
                    c.note != null ? '$dateStr · ${c.note}' : dateStr;
                return InsetTile(
                  title: '+${fmt.format(c.amount)}',
                  subtitle: subtitle,
                );
              }).toList(),
            );
          },
        ),
      ],
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
        ..invalidate(goalsProvider(Scope.personal));
    }
  }
}
