import 'package:aifb/features/ai_assistant/presentation/providers/ai_dependency_provider.dart';
import 'package:aifb/features/ai_assistant/presentation/providers/ai_extra_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RemindersTab extends ConsumerWidget {
  const RemindersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(remindersProvider);
    return Scaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Пока нет напоминаний'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final r = items[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  r.eventName,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await ref
                                      .read(aiAssistantRepositoryProvider)
                                      .deleteReminder(r.id);
                                  ref.invalidate(remindersProvider);
                                },
                              ),
                            ],
                          ),
                          Text(
                            'Через ${r.daysUntil} дн. • откладывать '
                            '${r.monthlyNeeded.toStringAsFixed(0)}/мес',
                          ),
                          if (r.targetAmount != null) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: (r.progressPercent / 100).clamp(0, 1).toDouble(),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${r.savedAmount.toStringAsFixed(0)} / '
                              '${r.targetAmount!.toStringAsFixed(0)}',
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    var date = DateTime.now().add(const Duration(days: 90));
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Событие'),
              ),
              TextField(
                controller: targetCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Сумма (необязательно)'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Дата: ${date.toIso8601String().split('T').first}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) setState(() => date = picked);
                    },
                    child: const Text('Выбрать'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  await ref.read(aiAssistantRepositoryProvider).createReminder(
                        eventName: nameCtrl.text.trim(),
                        eventDate: date,
                        targetAmount: double.tryParse(targetCtrl.text),
                      );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                child: const Text('Добавить'),
              ),
            ],
          ),
        ),
      ),
    );
    if (created ?? false) ref.invalidate(remindersProvider);
  }
}
