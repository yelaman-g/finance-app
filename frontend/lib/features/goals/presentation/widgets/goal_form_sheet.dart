import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/goals/presentation/providers/goals_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool?> showGoalForm(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _GoalForm(),
  );
}

class _GoalForm extends ConsumerStatefulWidget {
  const _GoalForm();

  @override
  ConsumerState<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<_GoalForm> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  DateTime? _deadline;
  bool _saving = false;
  String? _error;
  bool _shared = false;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final target = double.tryParse(_target.text.replaceAll(',', '.'));
    if (_name.text.trim().isEmpty || target == null || target <= 0) {
      setState(() => _error = 'Укажите название и цель > 0');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(goalsRepositoryProvider).create(
          name: _name.text.trim(),
          targetAmount: target,
          deadline: _deadline,
          shared: _shared,
        );
    if (!mounted) return;
    switch (result) {
      case Ok<dynamic>():
        Navigator.of(context).pop(true);
      case Err<dynamic>(failure: final f):
        setState(() {
          _saving = false;
          _error = f.toString();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Новая цель', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Название',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Целевая сумма',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            title: const Text('Семейная цель'),
            value: _shared,
            onChanged: (v) => setState(() => _shared = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  _deadline == null
                      ? 'Срок: не задан'
                      : 'Срок: ${_deadline!.toIso8601String().split('T').first}',
                ),
              ),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 90)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _deadline = picked);
                },
                child: const Text('Выбрать'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Создать'),
          ),
        ],
      ),
    );
  }
}
