import 'package:aifb/features/transactions/presentation/providers/finance_providers.dart';
import 'package:aifb/features/transactions/presentation/widgets/transaction_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(transactionsProvider);
    final fmt = NumberFormat.decimalPattern();
    return Scaffold(
      appBar: AppBar(title: const Text('Операции')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showTransactionForm(context);
          if (created ?? false) ref.invalidate(transactionsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(transactionsProvider.future),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 80),
              Center(child: Text('Ошибка: $e')),
            ],
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Пока нет операций')),
                ],
              );
            }
            return ListView.separated(
              itemCount: page.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final t = page.items[i];
                final sign = t.isIncome ? '+' : '-';
                return Dismissible(
                  key: ValueKey(t.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    await ref.read(financeRepositoryProvider).delete(t.id);
                    ref.invalidate(transactionsProvider);
                  },
                  child: ListTile(
                    title: Text(t.categoryName ?? '—'),
                    subtitle: Text(
                      '${t.occurredOn.toIso8601String().split('T').first}'
                      '${t.note != null ? ' · ${t.note}' : ''}',
                    ),
                    trailing: Text(
                      '$sign${fmt.format(t.amount)}',
                      style: TextStyle(
                        color: t.isIncome ? Colors.green : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
