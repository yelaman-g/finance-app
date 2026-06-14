import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/shopping_providers.dart';

class ShoppingPage extends ConsumerStatefulWidget {
  const ShoppingPage({super.key});

  @override
  ConsumerState<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends ConsumerState<ShoppingPage> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Список покупок')),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(shoppingListProvider.future),
              child: ref.watch(shoppingListProvider).when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (err, _) => ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: const Text('Ошибка загрузки. Потяните для повтора.'),
                        ),
                      ],
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text('Список пуст. Добавьте первый товар!'),
                            ),
                          ],
                        );
                      }
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final item = items[i];
                          return CheckboxListTile(
                            value: item.checked,
                            title: item.checked
                                ? Text(
                                    item.title,
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    ),
                                  )
                                : Text(item.title),
                            onChanged: (v) async {
                              await ref
                                  .read(shoppingRepositoryProvider)
                                  .toggle(item.id);
                              if (!mounted) return;
                              ref.invalidate(shoppingListProvider);
                            },
                            secondary: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await ref
                                    .read(shoppingRepositoryProvider)
                                    .delete(item.id);
                                if (!mounted) return;
                                ref.invalidate(shoppingListProvider);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Название товара...',
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) async {
                      final t = _titleController.text.trim();
                      if (t.isEmpty) return;
                      await ref.read(shoppingRepositoryProvider).add(t);
                      if (!mounted) return;
                      _titleController.clear();
                      ref.invalidate(shoppingListProvider);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final t = _titleController.text.trim();
                    if (t.isEmpty) return;
                    await ref.read(shoppingRepositoryProvider).add(t);
                    if (!mounted) return;
                    _titleController.clear();
                    ref.invalidate(shoppingListProvider);
                  },
                  child: const Text('Добавить'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
