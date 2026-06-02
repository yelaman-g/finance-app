import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/features/transactions/presentation/providers/finance_providers.dart';
import 'package:aifb/features/transactions/presentation/widgets/transaction_form_sheet.dart';
import 'package:aifb/shared/widgets/inset_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hig = HigColors.of(context);
    final async = ref.watch(transactionsProvider(Scope.personal));
    final fmt = NumberFormat.decimalPattern();

    return Scaffold(
      backgroundColor: hig.pageBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showTransactionForm(context);
          if (created ?? false) ref.invalidate(transactionsProvider(Scope.personal));
        },
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(transactionsProvider(Scope.personal).future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text('Операции'),
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
              data: (page) {
                if (page.items.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('Пока нет операций')),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverToBoxAdapter(
                    child: InsetSection(
                      children: page.items.map((t) {
                        final sign = t.isIncome ? '+' : '-';
                        final subtitle =
                            '${t.occurredOn.toIso8601String().split('T').first}'
                            '${t.note != null ? ' · ${t.note}' : ''}';
                        return Dismissible(
                          key: ValueKey(t.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            decoration: BoxDecoration(
                              color: hig.danger,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) async {
                            await ref.read(financeRepositoryProvider).delete(t.id);
                            ref.invalidate(transactionsProvider(Scope.personal));
                          },
                          child: InsetTile(
                            title: t.categoryName ?? '—',
                            subtitle: subtitle,
                            trailing: Text(
                              '$sign${fmt.format(t.amount)}',
                              style: TextStyle(
                                color: t.isIncome ? hig.success : hig.label,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
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
