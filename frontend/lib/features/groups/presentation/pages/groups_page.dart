import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/features/groups/presentation/providers/groups_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupsPage extends ConsumerWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(groupsProvider(Scope.personal));
    return Scaffold(
      appBar: AppBar(title: const Text('Группы')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Новая группа'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(groupsProvider(Scope.personal).future),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [const SizedBox(height: 80), Center(child: Text('Ошибка: $e'))],
          ),
          data: (groups) {
            if (groups.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Групп пока нет')),
                ],
              );
            }
            return ListView.separated(
              itemCount: groups.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final g = groups[i];
                return ListTile(
                  title: Text(g.name),
                  subtitle: Text(g.type),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ref.read(groupsRepositoryProvider).delete(g.id);
                      ref.invalidate(groupsProvider(Scope.personal));
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
    final name = TextEditingController();
    var type = 'EXPENSE';
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Новая группа'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'EXPENSE', label: Text('Расход')),
                  ButtonSegment(value: 'INCOME', label: Text('Доход')),
                ],
                selected: {type},
                onSelectionChanged: (s) => setState(() => type = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                await ref
                    .read(groupsRepositoryProvider)
                    .create(name: name.text.trim(), type: type);
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
    if (created ?? false) ref.invalidate(groupsProvider(Scope.personal));
  }
}
