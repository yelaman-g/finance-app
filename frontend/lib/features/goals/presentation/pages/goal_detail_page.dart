import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/core/utils/thousands_formatter.dart';
import 'package:aifb/features/goals/data/models/goal_model.dart';
import 'package:aifb/features/goals/presentation/providers/goals_providers.dart';
import 'package:aifb/features/goals/presentation/widgets/goal_form_sheet.dart';
import 'package:aifb/shared/widgets/inset_section.dart';
import 'package:aifb/shared/widgets/large_title_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
          inputFormatters: [ThousandsSeparatorInputFormatter()],
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
              double.tryParse(unformatAmount(controller.text)),
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
      // Момент достижения цели: празднуем, только когда этот взнос впервые
      // довёл накопления до целевой суммы.
      final goalRes = await ref.read(goalsRepositoryProvider).get(goalId);
      if (goalRes is Ok<GoalModel> && context.mounted) {
        final g = goalRes.value;
        final justCompleted = g.targetAmount > 0 &&
            g.savedAmount >= g.targetAmount &&
            (g.savedAmount - amount) < g.targetAmount;
        if (justCompleted) {
          await _celebrateGoal(context, g.name);
        }
      }
    }
  }

  Future<void> _celebrateGoal(BuildContext context, String name) {
    final hig = HigColors.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    Widget badge = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: hig.success.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.emoji_events_rounded, color: hig.success, size: 40),
    );
    if (!reduceMotion) {
      badge = badge
          .animate()
          .fadeIn(duration: 250.ms)
          .scale(
            begin: const Offset(0.7, 0.7),
            end: const Offset(1, 1),
            duration: 350.ms,
            curve: Curves.easeOutCubic,
          );
    }
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            badge,
            const SizedBox(height: 16),
            Text(
              'Цель достигнута! 🎉',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: hig.label,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '«$name» — вся сумма накоплена',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: hig.secondaryLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отлично'),
          ),
        ],
      ),
    );
  }
}
