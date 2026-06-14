import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/features/auth/domain/entities/auth_user.dart';
import 'package:aifb/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aifb/features/auth/presentation/state/auth_state.dart';
import 'package:aifb/features/reactions/presentation/widgets/reaction_bar.dart';
import 'package:aifb/features/transactions/presentation/providers/finance_providers.dart';
import 'package:aifb/features/transactions/presentation/widgets/transaction_form_sheet.dart';
import 'package:aifb/shared/widgets/inset_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({this.scope = Scope.personal, super.key});

  final Scope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hig = HigColors.of(context);
    final async = ref.watch(transactionsProvider(scope));
    final fmt = NumberFormat.decimalPattern();
    final authState = ref.watch(authControllerProvider);
    final AuthUser? currentUser =
        authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: hig.pageBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showTransactionForm(context);
          if (created ?? false) ref.invalidate(transactionsProvider(scope));
        },
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(transactionsProvider(scope).future),
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
                final txIds = page.items.map((t) => t.id).toList();
                final showReactions =
                    scope == Scope.family && currentUser != null;
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
                            ref.invalidate(transactionsProvider(scope));
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InsetTile(
                                title: t.categoryName ?? '—',
                                subtitle: subtitle,
                                trailing: Text(
                                  '$sign${fmt.format(t.amount)}',
                                  style: TextStyle(
                                    color:
                                        t.isIncome ? hig.success : hig.label,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (showReactions)
                                ReactionBar(
                                  txId: t.id,
                                  currentUserId: currentUser!.id,
                                  txIds: txIds,
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
