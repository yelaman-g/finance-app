import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/features/budgets/presentation/providers/budgets_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  Color _statusColor(String status) => switch (status) {
        'EXCEEDED' => Colors.red,
        'WARNING' => Colors.orange,
        _ => Colors.green,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(budgetsProvider(Scope.personal));
    final fmt = NumberFormat.decimalPattern();
    return Scaffold(
      appBar: AppBar(title: const Text('Бюджеты')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(budgetsProvider(Scope.personal).future),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 80),
              Center(child: Text('Ошибка: $e')),
            ],
          ),
          data: (budgets) {
            if (budgets.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Лимитов пока нет')),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: budgets.length,
              itemBuilder: (_, i) {
                final b = budgets[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                b.targetName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${fmt.format(b.spent)} / ${fmt.format(b.amount)}',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await ref
                                    .read(budgetsRepositoryProvider)
                                    .delete(b.id);
                                ref.invalidate(budgetsProvider(Scope.personal));
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (b.percentage / 100).clamp(0, 1).toDouble(),
                          color: _statusColor(b.status),
                          backgroundColor: Colors.black12,
                        ),
                      ],
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
