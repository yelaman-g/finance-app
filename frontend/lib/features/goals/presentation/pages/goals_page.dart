import 'package:aifb/app/router/routes.dart';
import 'package:aifb/core/errors/error_text.dart';
import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/features/goals/presentation/providers/goals_providers.dart';
import 'package:aifb/features/goals/presentation/widgets/goal_form_sheet.dart';
import 'package:aifb/shared/widgets/inset_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hig = HigColors.of(context);
    final async = ref.watch(goalsProvider(Scope.personal));
    final fmt = NumberFormat.decimalPattern();

    return Scaffold(
      backgroundColor: hig.pageBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showGoalForm(context);
          if (created ?? false) ref.invalidate(goalsProvider(Scope.personal));
        },
        icon: const Icon(Icons.add),
        label: const Text('Новая цель'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(goalsProvider(Scope.personal).future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text('Цели'),
              backgroundColor: hig.pageBackground,
              surfaceTintColor: Colors.transparent,
            ),
            async.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text(errorText(e))),
              ),
              data: (goals) {
                if (goals.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                        child: Text(
                            'Целей пока нет. Создайте первую, чтобы начать копить.')),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverToBoxAdapter(
                    child: InsetSection(
                      children: goals.map((g) {
                        final done = g.targetAmount > 0 &&
                            g.savedAmount >= g.targetAmount;
                        return InkWell(
                          onTap: () => context
                              .push('${AppRoutes.goals.path}/${g.id}'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (done) ...[
                                      Icon(Icons.emoji_events_rounded,
                                          color: hig.success, size: 18),
                                      const SizedBox(width: 6),
                                    ],
                                    Expanded(
                                      child: Text(
                                        g.name,
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: hig.label,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: hig.secondaryLabel,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: (g.percentage / 100)
                                      .clamp(0, 1)
                                      .toDouble(),
                                  color: done ? hig.success : hig.accent,
                                  backgroundColor: hig.separator,
                                  borderRadius: BorderRadius.circular(4),
                                  minHeight: 6,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  done
                                      ? 'Цель достигнута'
                                      : '${fmt.format(g.savedAmount)} / '
                                          '${fmt.format(g.targetAmount)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: done ? hig.success : hig.secondaryLabel,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
