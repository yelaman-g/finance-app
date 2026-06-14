import 'package:aifb/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aifb/features/auth/presentation/state/auth_state.dart';
import 'package:aifb/features/capsules/data/dto/capsule.dart';
import 'package:aifb/features/capsules/presentation/providers/capsule_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CapsulesPage extends ConsumerStatefulWidget {
  const CapsulesPage({super.key});

  @override
  ConsumerState<CapsulesPage> createState() => _CapsulesPageState();
}

class _CapsulesPageState extends ConsumerState<CapsulesPage> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _delete(Capsule capsule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить капсулу?'),
        content: Text(
          'Капсула «${capsule.title}» будет удалена безвозвратно.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(capsuleRepositoryProvider).delete(capsule.id);
    if (!mounted) return;
    ref.invalidate(capsulesProvider);
  }

  Future<void> _showCreateDialog() async {
    _titleController.clear();
    _messageController.clear();

    DateTime? pickedDate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _CreateCapsuleDialog(
        titleController: _titleController,
        messageController: _messageController,
        onDatePicked: (d) => pickedDate = d,
      ),
    );

    if (confirmed != true) return;

    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty || pickedDate == null) return;

    await ref
        .read(capsuleRepositoryProvider)
        .create(title, message, pickedDate!);
    if (!mounted) return;
    ref.invalidate(capsulesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final currentUserId = auth is AuthAuthenticated ? auth.user.id : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Капсула времени')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Создать капсулу',
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(capsulesProvider.future),
        child: ref.watch(capsulesProvider).when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child:
                        Text('Ошибка загрузки. Потяните для повтора.'),
                  ),
                ],
              ),
              data: (capsules) {
                if (capsules.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'Капсул пока нет. Создайте первую!',
                        ),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: capsules.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _CapsuleCard(
                    capsule: capsules[i],
                    currentUserId: currentUserId,
                    onDelete: () => _delete(capsules[i]),
                  ),
                );
              },
            ),
      ),
    );
  }
}

// ── Capsule card ──────────────────────────────────────────────────────────────

class _CapsuleCard extends StatelessWidget {
  const _CapsuleCard({
    required this.capsule,
    required this.currentUserId,
    required this.onDelete,
  });

  final Capsule capsule;
  final String? currentUserId;
  final VoidCallback onDelete;

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  int _daysRemaining(DateTime openDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final open = DateTime(openDate.year, openDate.month, openDate.day);
    return open.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final isCreator =
        currentUserId != null && capsule.createdBy == currentUserId;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onLongPress: isCreator ? onDelete : null,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 12),
                child: Icon(
                  capsule.locked
                      ? Icons.lock_clock_rounded
                      : Icons.lock_open_rounded,
                  color: capsule.locked
                      ? colorScheme.primary
                      : colorScheme.tertiary,
                  size: 28,
                ),
              ),

              // ── Content ────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            capsule.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium,
                          ),
                        ),
                        if (isCreator)
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 20),
                            tooltip: 'Удалить',
                            onPressed: onDelete,
                            color: colorScheme.error,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (capsule.locked) ...[
                      Text(
                        'Откроется ${_formatDate(capsule.openDate)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'через ${_daysRemaining(capsule.openDate)} дн.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ] else ...[
                      if (capsule.message != null &&
                          capsule.message!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            capsule.message!,
                            style:
                                Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Create capsule dialog ─────────────────────────────────────────────────────

class _CreateCapsuleDialog extends StatefulWidget {
  const _CreateCapsuleDialog({
    required this.titleController,
    required this.messageController,
    required this.onDatePicked,
  });

  final TextEditingController titleController;
  final TextEditingController messageController;
  final ValueChanged<DateTime> onDatePicked;

  @override
  State<_CreateCapsuleDialog> createState() =>
      _CreateCapsuleDialogState();
}

class _CreateCapsuleDialogState extends State<_CreateCapsuleDialog> {
  DateTime? _selectedDate;

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: tomorrow,
      lastDate: DateTime(now.year + 100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      widget.onDatePicked(picked);
    }
  }

  bool get _isValid =>
      widget.titleController.text.trim().isNotEmpty &&
      widget.messageController.text.trim().isNotEmpty &&
      _selectedDate != null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новая капсула'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: widget.titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: 'Например: Нашей семье через 5 лет',
              ),
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.messageController,
              decoration: const InputDecoration(
                labelText: 'Сообщение',
                hintText: 'Что хотите сказать в будущем?',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDate != null
                          ? 'Откроется: ${_formatDate(_selectedDate!)}'
                          : 'Выберите дату открытия',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: _selectedDate != null
                                ? null
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isValid
              ? () => Navigator.of(context).pop(true)
              : null,
          child: const Text('Создать'),
        ),
      ],
    );
  }
}
