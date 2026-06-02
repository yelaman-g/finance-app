import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/goals/data/models/goal_model.dart';
import 'package:aifb/features/goals/presentation/providers/goals_providers.dart';
import 'package:aifb/shared/widgets/hig_button.dart';
import 'package:aifb/shared/widgets/hig_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool?> showGoalForm(BuildContext context, {GoalModel? existing}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _GoalForm(existing: existing),
  );
}

class _GoalForm extends ConsumerStatefulWidget {
  const _GoalForm({this.existing});

  final GoalModel? existing;

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
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _name.text = widget.existing!.name;
      _target.text = widget.existing!.targetAmount.toStringAsFixed(0);
      _deadline = widget.existing!.deadline;
    }
  }

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
    final Result<GoalModel> result;
    if (widget.existing != null) {
      result = await ref.read(goalsRepositoryProvider).update(
            id: widget.existing!.id,
            name: _name.text.trim(),
            targetAmount: target,
            deadline: _deadline,
            icon: widget.existing!.icon,
            color: widget.existing!.color,
          );
    } else {
      result = await ref.read(goalsRepositoryProvider).create(
            name: _name.text.trim(),
            targetAmount: target,
            deadline: _deadline,
            shared: _shared,
          );
    }
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
    final hig = HigColors.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: hig.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null ? 'Новая цель' : 'Изменить цель',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: hig.label,
            ),
          ),
          const SizedBox(height: 16),
          HigTextField(
            controller: _name,
            label: 'Название',
          ),
          const SizedBox(height: 12),
          HigTextField(
            controller: _target,
            label: 'Целевая сумма',
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          if (widget.existing == null) ...[
            const SizedBox(height: 4),
            SwitchListTile(
              title:
                  Text('Семейная цель', style: TextStyle(color: hig.label)),
              value: _shared,
              onChanged: (v) => setState(() => _shared = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  _deadline == null
                      ? 'Срок: не задан'
                      : 'Срок: ${_deadline!.toIso8601String().split('T').first}',
                  style: TextStyle(color: hig.secondaryLabel),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.now().add(const Duration(days: 90)),
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
            Text(
              _error!,
              style: TextStyle(color: hig.danger, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          HigButton(
            label: widget.existing == null ? 'Создать' : 'Сохранить',
            onPressed: _saving ? null : _submit,
            loading: _saving,
          ),
        ],
      ),
    );
  }
}
