import 'package:aifb/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aifb/features/auth/presentation/state/auth_state.dart';
import 'package:aifb/features/polls/data/dto/poll.dart';
import 'package:aifb/features/polls/presentation/providers/poll_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PollsPage extends ConsumerStatefulWidget {
  const PollsPage({super.key});

  @override
  ConsumerState<PollsPage> createState() => _PollsPageState();
}

class _PollsPageState extends ConsumerState<PollsPage> {
  // ── Create-poll dialog state ──────────────────────────────────────────────
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _vote(String pollId, String optionId) async {
    await ref.read(pollRepositoryProvider).vote(pollId, optionId);
    if (!mounted) return;
    ref.invalidate(pollsProvider);
  }

  Future<void> _close(String pollId) async {
    await ref.read(pollRepositoryProvider).close(pollId);
    if (!mounted) return;
    ref.invalidate(pollsProvider);
  }

  Future<void> _showCreateDialog() async {
    // Reset controllers
    _questionController.clear();
    for (final c in _optionControllers) {
      c.dispose();
    }
    _optionControllers
      ..clear()
      ..add(TextEditingController())
      ..add(TextEditingController());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _CreatePollDialog(
        questionController: _questionController,
        optionControllers: _optionControllers,
      ),
    );

    if (confirmed != true) return;

    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (question.isEmpty || options.length < 2) return;

    await ref.read(pollRepositoryProvider).create(question, options);
    if (!mounted) return;
    ref.invalidate(pollsProvider);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final currentUserId = auth is AuthAuthenticated ? auth.user.id : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Голосования')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Создать голосование',
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(pollsProvider.future),
        child: ref.watch(pollsProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text('Ошибка загрузки. Потяните для повтора.'),
                  ),
                ],
              ),
              data: (polls) {
                if (polls.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'Голосований пока нет. Создайте первое!',
                        ),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: polls.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _PollCard(
                    poll: polls[i],
                    currentUserId: currentUserId,
                    onVote: (optionId) => _vote(polls[i].id, optionId),
                    onClose: () => _close(polls[i].id),
                  ),
                );
              },
            ),
      ),
    );
  }
}

// ── Poll card ────────────────────────────────────────────────────────────────

class _PollCard extends StatelessWidget {
  const _PollCard({
    required this.poll,
    required this.currentUserId,
    required this.onVote,
    required this.onClose,
  });

  final Poll poll;
  final String? currentUserId;
  final ValueChanged<String> onVote;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isCreator = currentUserId != null && poll.createdBy == currentUserId;
    final totalVotes = poll.options.fold<int>(0, (s, o) => s + o.votes);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    poll.question,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (poll.closed)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Завершён',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Options ───────────────────────────────────────────────────
            ...poll.options.map(
              (option) => _OptionRow(
                option: option,
                totalVotes: totalVotes,
                isSelected: poll.myVoteOptionId == option.id,
                canVote: !poll.closed,
                onTap: () => onVote(option.id),
              ),
            ),

            // ── Footer ────────────────────────────────────────────────────
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalVotes ${_votesLabel(totalVotes)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (isCreator && !poll.closed)
                  TextButton(
                    onPressed: onClose,
                    child: const Text('Завершить'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _votesLabel(int count) {
    if (count % 100 >= 11 && count % 100 <= 14) return 'голосов';
    switch (count % 10) {
      case 1:
        return 'голос';
      case 2:
      case 3:
      case 4:
        return 'голоса';
      default:
        return 'голосов';
    }
  }
}

// ── Option row with vote-share bar ───────────────────────────────────────────

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.totalVotes,
    required this.isSelected,
    required this.canVote,
    required this.onTap,
  });

  final PollOption option;
  final int totalVotes;
  final bool isSelected;
  final bool canVote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fraction = totalVotes > 0 ? option.votes / totalVotes : 0.0;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: canVote ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            children: [
              // Vote-share background bar
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(
                  height: 44,
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest,
                ),
              ),
              // Label row
              SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      if (isSelected) const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          option.text,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : null,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '${option.votes}',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Create poll dialog ────────────────────────────────────────────────────────

class _CreatePollDialog extends StatefulWidget {
  const _CreatePollDialog({
    required this.questionController,
    required this.optionControllers,
  });

  final TextEditingController questionController;
  final List<TextEditingController> optionControllers;

  @override
  State<_CreatePollDialog> createState() => _CreatePollDialogState();
}

class _CreatePollDialogState extends State<_CreatePollDialog> {
  List<TextEditingController> get _opts => widget.optionControllers;

  void _addOption() {
    if (_opts.length >= 10) return;
    setState(() => _opts.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_opts.length <= 2) return;
    setState(() {
      _opts[index].dispose();
      _opts.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новое голосование'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: widget.questionController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Вопрос',
                hintText: 'Что хотите спросить у семьи?',
              ),
              textInputAction: TextInputAction.next,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Text(
              'Варианты ответов',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            ...List.generate(_opts.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _opts[i],
                        decoration: InputDecoration(
                          hintText: 'Вариант ${i + 1}',
                          isDense: true,
                        ),
                        textInputAction: i < _opts.length - 1
                            ? TextInputAction.next
                            : TextInputAction.done,
                      ),
                    ),
                    if (_opts.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        tooltip: 'Удалить вариант',
                        onPressed: () => _removeOption(i),
                      ),
                  ],
                ),
              );
            }),
            if (_opts.length < 10)
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Добавить вариант'),
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
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Создать'),
        ),
      ],
    );
  }
}
