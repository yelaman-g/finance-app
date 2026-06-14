import 'package:aifb/core/utils/thousands_formatter.dart';
import 'package:aifb/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _types = ['OTHER', 'BIRTHDAY', 'MEETING', 'SCHOOL'];
const _freqs = ['NONE', 'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'];

const _typeLabels = {
  'OTHER': 'Другое',
  'BIRTHDAY': 'День рождения',
  'MEETING': 'Встреча',
  'SCHOOL': 'Учёба',
};
const _freqLabels = {
  'NONE': 'Без повтора',
  'DAILY': 'Ежедневно',
  'WEEKLY': 'Еженедельно',
  'MONTHLY': 'Ежемесячно',
  'YEARLY': 'Ежегодно',
};

Future<bool?> showEventForm(
  BuildContext context,
  WidgetRef ref, {
  required DateTime initialDate,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _EventForm(initialDate: initialDate, ref: ref),
  );
}

class _EventForm extends StatefulWidget {
  const _EventForm({required this.initialDate, required this.ref});
  final DateTime initialDate;
  final WidgetRef ref;

  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  final _title = TextEditingController();
  final _budget = TextEditingController();
  final _notifyController = TextEditingController(text: '1,0');
  late DateTime _date = widget.initialDate;
  String _type = 'OTHER';
  String _freq = 'NONE';
  bool _shared = false;
  bool _saving = false;

  String _d(DateTime d) => d.toIso8601String().split('T').first;

  @override
  void dispose() {
    _title.dispose();
    _budget.dispose();
    _notifyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('Дата: ${_d(_date)}')),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: const Text('Выбрать'),
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Тип'),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(_typeLabels[t] ?? t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? 'OTHER'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _freq,
              decoration: const InputDecoration(labelText: 'Повтор'),
              items: _freqs
                  .map((f) => DropdownMenuItem(value: f, child: Text(_freqLabels[f] ?? f)))
                  .toList(),
              onChanged: (v) => setState(() => _freq = v ?? 'NONE'),
            ),
            if (_freq == 'NONE')
              TextField(
                controller: _budget,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration:
                    const InputDecoration(labelText: 'Бюджет (необязательно)'),
              ),
            SwitchListTile(
              title: const Text('Семейное событие'),
              value: _shared,
              onChanged: (v) => setState(() => _shared = v),
              contentPadding: EdgeInsets.zero,
            ),
            TextField(
              controller: _notifyController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Уведомлять за (дни, через запятую)',
                hintText: '1,0',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final notifyDays = _notifyController.text
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();
    final body = <String, dynamic>{
      'title': _title.text.trim(),
      'startDate': _d(_date),
      'allDay': true,
      'type': _type,
      'recurFreq': _freq,
      'shared': _shared,
      'notifyDaysBefore': notifyDays,
    };
    if (_freq == 'NONE') {
      final b = double.tryParse(unformatAmount(_budget.text));
      if (b != null) body['budget'] = b;
    }
    try {
      await widget.ref.read(eventRepositoryProvider).createEvent(body);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось создать событие')),
        );
      }
    }
  }
}
