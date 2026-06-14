import 'package:aifb/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aifb/features/auth/presentation/state/auth_state.dart';
import 'package:aifb/features/wishlist/data/dto/wishlist_item.dart';
import 'package:aifb/features/wishlist/presentation/providers/wishlist_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WishlistPage extends ConsumerStatefulWidget {
  const WishlistPage({super.key});

  @override
  ConsumerState<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends ConsumerState<WishlistPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String? _currentUserId() {
    final auth = ref.read(authControllerProvider);
    if (auth is AuthAuthenticated) return auth.user.id;
    return null;
  }

  Future<void> _showAddDialog() async {
    _titleController.clear();
    _noteController.clear();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить желание'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: 'Что хочешь получить?',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Заметка (необязательно)',
                hintText: 'Ссылка, размер, цвет...',
              ),
              textInputAction: TextInputAction.done,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final note = _noteController.text.trim();
    await ref
        .read(wishlistRepositoryProvider)
        .add(title, note.isEmpty ? null : note);
    if (!mounted) return;
    ref.invalidate(wishlistProvider);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final currentUserId =
        auth is AuthAuthenticated ? auth.user.id : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Вишлисты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить желание',
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(wishlistProvider.future),
        child: ref.watch(wishlistProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'Ошибка загрузки. Потяните для повтора.',
                    ),
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
                        child: Text(
                          'Вишлисты пусты. Добавьте первое желание!',
                        ),
                      ),
                    ],
                  );
                }
                // Group items by owner
                final grouped = <String, List<WishlistItem>>{};
                final ownerNames = <String, String>{};
                for (final item in items) {
                  grouped.putIfAbsent(item.ownerId, () => []).add(item);
                  ownerNames[item.ownerId] = item.ownerName;
                }
                // Own section first, then others alphabetically
                final ownerIds = grouped.keys.toList()
                  ..sort((a, b) {
                    if (a == currentUserId) return -1;
                    if (b == currentUserId) return 1;
                    return (ownerNames[a] ?? '').compareTo(ownerNames[b] ?? '');
                  });

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: ownerIds.length,
                  itemBuilder: (ctx, sectionIndex) {
                    final ownerId = ownerIds[sectionIndex];
                    final ownerItems = grouped[ownerId]!;
                    final isOwn = ownerId == currentUserId;
                    final sectionTitle = isOwn
                        ? 'Мой список'
                        : (ownerNames[ownerId] ?? 'Неизвестно');

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Text(
                            sectionTitle.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  letterSpacing: 0.5,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                        ...ownerItems.map(
                          (item) => _WishlistItemTile(
                            item: item,
                            isOwn: isOwn,
                            currentUserId: currentUserId,
                            onDelete: () async {
                              await ref
                                  .read(wishlistRepositoryProvider)
                                  .delete(item.id);
                              if (!mounted) return;
                              ref.invalidate(wishlistProvider);
                            },
                            onReserve: () async {
                              if (item.reserved &&
                                  item.reservedBy == currentUserId) {
                                await ref
                                    .read(wishlistRepositoryProvider)
                                    .unreserve(item.id);
                              } else {
                                await ref
                                    .read(wishlistRepositoryProvider)
                                    .reserve(item.id);
                              }
                              if (!mounted) return;
                              ref.invalidate(wishlistProvider);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                );
              },
            ),
      ),
    );
  }
}

class _WishlistItemTile extends StatelessWidget {
  const _WishlistItemTile({
    required this.item,
    required this.isOwn,
    required this.currentUserId,
    required this.onDelete,
    required this.onReserve,
  });

  final WishlistItem item;
  final bool isOwn;
  final String? currentUserId;
  final VoidCallback onDelete;
  final VoidCallback onReserve;

  String get _reserveLabel {
    if (!item.reserved) return 'Зарезервировать';
    if (item.reservedBy == currentUserId) return 'Вы зарезервировали';
    return 'Зарезервировано';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.title),
      subtitle: item.note != null && item.note!.isNotEmpty
          ? Text(
              item.note!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: isOwn
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Удалить',
              onPressed: onDelete,
            )
          : TextButton(
              onPressed: (item.reserved && item.reservedBy != currentUserId)
                  ? null
                  : onReserve,
              child: Text(
                _reserveLabel,
                style: TextStyle(
                  color: item.reserved
                      ? (item.reservedBy == currentUserId
                          ? Colors.green
                          : Colors.grey)
                      : null,
                ),
              ),
            ),
    );
  }
}
