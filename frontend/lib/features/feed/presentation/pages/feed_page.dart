import 'package:aifb/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aifb/features/auth/presentation/state/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/dto/moment.dart';
import '../providers/feed_providers.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  late final TextEditingController _composeController;

  @override
  void initState() {
    super.initState();
    _composeController = TextEditingController();
  }

  @override
  void dispose() {
    _composeController.dispose();
    super.dispose();
  }

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays < 7) return '${diff.inDays} д назад';
    return DateFormat('d MMM', 'ru').format(dt);
  }

  Future<void> _publish() async {
    final text = _composeController.text.trim();
    if (text.isEmpty) return;
    await ref.read(feedRepositoryProvider).post(text);
    if (!mounted) return;
    _composeController.clear();
    ref.invalidate(feedProvider);
  }

  Future<void> _toggleLike(Moment moment) async {
    final repo = ref.read(feedRepositoryProvider);
    if (moment.likedByMe) {
      await repo.unlike(moment.id);
    } else {
      await repo.like(moment.id);
    }
    if (!mounted) return;
    ref.invalidate(feedProvider);
  }

  Future<void> _confirmDelete(Moment moment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить момент?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(feedRepositoryProvider).delete(moment.id);
    if (!mounted) return;
    ref.invalidate(feedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final currentUserId = auth is AuthAuthenticated ? auth.user.id : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Семейная лента')),
      body: Column(
        children: [
          // ── Compose area ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _composeController,
                    maxLines: 3,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Поделитесь моментом с семьёй…',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _publish,
                  child: const Text('Опубликовать'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Feed list ─────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(feedProvider.future),
              child: ref.watch(feedProvider).when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
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
                    data: (moments) {
                      if (moments.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'Лента пуста. Поделитесь первым моментом!',
                              ),
                            ),
                          ],
                        );
                      }
                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: moments.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (ctx, i) => _MomentCard(
                          moment: moments[i],
                          currentUserId: currentUserId,
                          relativeTime: _relativeTime(moments[i].createdAt),
                          onLike: () => _toggleLike(moments[i]),
                          onDelete: () => _confirmDelete(moments[i]),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Moment card ──────────────────────────────────────────────────────────────

class _MomentCard extends StatelessWidget {
  const _MomentCard({
    required this.moment,
    required this.currentUserId,
    required this.relativeTime,
    required this.onLike,
    required this.onDelete,
  });

  final Moment moment;
  final String? currentUserId;
  final String relativeTime;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isOwn = currentUserId != null && moment.authorId == currentUserId;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: author + time + delete ────────────────────────────
            Row(
              children: [
                Text(
                  moment.authorName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  relativeTime,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const Spacer(),
                if (isOwn)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Удалить',
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Text ──────────────────────────────────────────────────────
            Text(moment.text),
            const SizedBox(height: 10),

            // ── Like button ───────────────────────────────────────────────
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    moment.likedByMe
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: moment.likedByMe
                        ? Colors.red
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  tooltip: moment.likedByMe ? 'Убрать лайк' : 'Лайк',
                  onPressed: onLike,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                Text(
                  '${moment.likes}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
