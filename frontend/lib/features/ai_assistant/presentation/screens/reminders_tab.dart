import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/core/utils/thousands_formatter.dart';
import 'package:aifb/features/ai_assistant/data/dto/ai_dtos.dart';
import 'package:aifb/features/ai_assistant/presentation/providers/ai_dependency_provider.dart';
import 'package:aifb/features/ai_assistant/presentation/providers/ai_extra_providers.dart';
import 'package:aifb/shared/widgets/hig_button.dart';
import 'package:aifb/shared/widgets/hig_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RemindersTab extends ConsumerWidget {
  const RemindersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hig = HigColors.of(context);
    final async = ref.watch(remindersProvider);
    return Scaffold(
      backgroundColor: hig.pageBackground,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (items) => items.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        size: 64, color: hig.secondaryLabel),
                    const SizedBox(height: 16),
                    Text(
                      'Пока нет напоминаний',
                      style: TextStyle(
                          fontSize: 17, color: hig.secondaryLabel),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Нажмите «+», чтобы добавить первое',
                      style: TextStyle(
                          fontSize: 13, color: hig.secondaryLabel),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final r = items[i];
                  final progress =
                      (r.progressPercent / 100).clamp(0.0, 1.0).toDouble();
                  return _ReminderCard(
                    reminder: r,
                    progress: progress,
                    onDelete: () async {
                      await ref
                          .read(aiAssistantRepositoryProvider)
                          .deleteReminder(r.id);
                      ref.invalidate(remindersProvider);
                    },
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        backgroundColor: hig.accent,
        foregroundColor: Colors.white,
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddReminderSheet(
        nameCtrl: nameCtrl,
        targetCtrl: targetCtrl,
        initialDate: date,
        onDateChanged: (d) => date = d,
        onSubmit: () async {
          if (nameCtrl.text.trim().isEmpty) return;
          await ref.read(aiAssistantRepositoryProvider).createReminder(
                eventName: nameCtrl.text.trim(),
                eventDate: date,
                targetAmount: double.tryParse(unformatAmount(targetCtrl.text)),
              );
          if (ctx.mounted) Navigator.pop(ctx, true);
        },
      ),
    );
    if (created ?? false) ref.invalidate(remindersProvider);
  }
}

// ─── Card widget ─────────────────────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.progress,
    required this.onDelete,
  });

  final Reminder reminder;
  final double progress;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);
    final r = reminder;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: hig.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.eventName,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: hig.label),
                  ),
                ),
                GestureDetector(
                  onTap: () => _confirmDelete(context, onDelete),
                  child: Icon(Icons.delete_outline,
                      color: hig.danger, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Secondary info
            Text(
              'Через ${r.daysUntil} дн. • откладывать '
              '${r.monthlyNeeded.toStringAsFixed(0)} ₸/мес',
              style:
                  TextStyle(fontSize: 13, color: hig.secondaryLabel),
            ),
            // Progress section
            if (r.targetAmount != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: hig.separator,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(hig.accent),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${r.savedAmount.toStringAsFixed(0)} ₸ накоплено',
                    style: TextStyle(
                        fontSize: 12, color: hig.secondaryLabel),
                  ),
                  Text(
                    'из ${r.targetAmount!.toStringAsFixed(0)} ₸',
                    style: TextStyle(
                        fontSize: 12, color: hig.secondaryLabel),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, VoidCallback onDelete) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить напоминание?'),
        content: const Text(
            'Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Удалить',
                style: TextStyle(color: HigColors.of(context).danger)),
          ),
        ],
      ),
    );
    if (ok ?? false) onDelete();
  }
}

// ─── Bottom sheet widget ─────────────────────────────────────────────────────

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet({
    required this.nameCtrl,
    required this.targetCtrl,
    required this.initialDate,
    required this.onDateChanged,
    required this.onSubmit,
  });

  final TextEditingController nameCtrl;
  final TextEditingController targetCtrl;
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateChanged;
  final Future<void> Function() onSubmit;

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  late DateTime _date;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: hig.pageBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: hig.separator,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Новое напоминание',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: hig.label),
          ),
          const SizedBox(height: 16),
          HigTextField(
            controller: widget.nameCtrl,
            label: 'Событие',
            hint: 'например, Отпуск',
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          HigTextField(
            controller: widget.targetCtrl,
            label: 'Целевая сумма (необязательно)',
            hint: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [ThousandsSeparatorInputFormatter()],
          ),
          const SizedBox(height: 12),
          // Date picker row
          DecoratedBox(
            decoration: BoxDecoration(
              color: hig.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: hig.separator),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now(),
                  lastDate:
                      DateTime.now().add(const Duration(days: 3650)),
                  locale: const Locale('ru'),
                );
                if (picked != null) {
                  setState(() => _date = picked);
                  widget.onDateChanged(picked);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: hig.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Дата события: ${_formatDate(_date)}',
                        style: TextStyle(
                            fontSize: 17, color: hig.label),
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: hig.secondaryLabel, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          HigButton(
            label: 'Добавить',
            loading: _loading,
            onPressed: () async {
              setState(() => _loading = true);
              await widget.onSubmit();
              if (mounted) setState(() => _loading = false);
            },
          ),
        ],
      ),
    );
  }
}
