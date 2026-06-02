import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/features/budgets/presentation/providers/budgets_providers.dart';
import 'package:aifb/shared/widgets/inset_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  Color _statusColor(String status, HigColors hig) => switch (status) {
        'EXCEEDED' => hig.danger,
        'WARNING' => hig.warning,
        _ => hig.success,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hig = HigColors.of(context);
    final async = ref.watch(budgetsProvider(Scope.personal));
    final fmt = NumberFormat.decimalPattern();

    return Scaffold(
      backgroundColor: hig.pageBackground,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(budgetsProvider(Scope.personal).future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text('Бюджеты'),
              backgroundColor: hig.pageBackground,
              surfaceTintColor: Colors.transparent,
            ),
            async.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Ошибка: $e')),
              ),
              data: (budgets) {
                if (budgets.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('Лимитов пока нет')),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverToBoxAdapter(
                    child: InsetSection(
                      children: budgets.map((b) {
                        final color = _statusColor(b.status, hig);
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      b.targetName,
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: hig.label,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${fmt.format(b.spent)} / ${fmt.format(b.amount)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: hig.secondaryLabel,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: hig.danger,
                                    ),
                                    onPressed: () async {
                                      await ref
                                          .read(budgetsRepositoryProvider)
                                          .delete(b.id);
                                      ref.invalidate(
                                        budgetsProvider(Scope.personal),
                                      );
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value:
                                    (b.percentage / 100).clamp(0, 1).toDouble(),
                                color: color,
                                backgroundColor: hig.separator,
                                borderRadius: BorderRadius.circular(4),
                                minHeight: 6,
                              ),
                            ],
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
