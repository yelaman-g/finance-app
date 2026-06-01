import 'package:aifb/features/categorization/presentation/providers/categorization_providers.dart';
import 'package:aifb/features/transactions/presentation/providers/finance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RulesPage extends ConsumerWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(rulesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Правила категоризации')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Новое правило'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(rulesProvider.future),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 80),
              Center(child: Text('Ошибка: $e')),
            ],
          ),
          data: (rules) {
            if (rules.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Правил пока нет')),
                ],
              );
            }
            return ListView.separated(
              itemCount: rules.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = rules[i];
                return ListTile(
                  title: Text('«${r.keyword}» → ${r.categoryName}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ref
                          .read(categorizationRepositoryProvider)
                          .delete(r.id);
                      ref.invalidate(rulesProvider);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final keyword = TextEditingController();
    String? categoryId;
    final catsAsync =
        await ref.read(categoriesProvider('EXPENSE').future);
    if (!context.mounted) return;
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Новое правило'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyword,
                decoration: const InputDecoration(
                  labelText: 'Ключевое слово',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: categoryId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Категория'),
                items: catsAsync
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => categoryId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () async {
                if (keyword.text.trim().isEmpty || categoryId == null) return;
                await ref
                    .read(categorizationRepositoryProvider)
                    .create(
                      keyword: keyword.text.trim(),
                      categoryId: categoryId!,
                    );
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
    if (created ?? false) ref.invalidate(rulesProvider);
  }
}
