import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/core/errors/failure_message.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/core/utils/thousands_formatter.dart';
import 'package:aifb/features/budgets/presentation/providers/budgets_providers.dart';
import 'package:aifb/features/groups/presentation/providers/groups_providers.dart';
import 'package:aifb/features/transactions/presentation/providers/finance_providers.dart';
import 'package:aifb/shared/widgets/hig_button.dart';
import 'package:aifb/shared/widgets/hig_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Модальная форма создания месячного лимита (категория или группа расходов).
/// Возвращает true при успехе.
Future<bool?> showBudgetForm(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _BudgetForm(),
  );
}

class _BudgetForm extends ConsumerStatefulWidget {
  const _BudgetForm();

  @override
  ConsumerState<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<_BudgetForm> {
  final _amount = TextEditingController();
  final _threshold = TextEditingController(text: '80');
  String _targetType = 'CATEGORY';
  String? _targetId;
  bool _shared = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _threshold.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(unformatAmount(_amount.text));
    if (amount == null || amount <= 0 || _targetId == null) {
      setState(() => _error = 'Выберите цель и укажите сумму');
      return;
    }
    final threshold =
        (int.tryParse(_threshold.text) ?? 80).clamp(1, 100);
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(budgetsRepositoryProvider).create(
          targetType: _targetType,
          amount: amount,
          categoryId: _targetType == 'CATEGORY' ? _targetId : null,
          groupId: _targetType == 'GROUP' ? _targetId : null,
          shared: _shared,
          notifyThresholdPercent: threshold,
        );
    if (!mounted) return;
    switch (result) {
      case Ok<dynamic>():
        Navigator.of(context).pop(true);
      case Err<dynamic>(failure: final f):
        setState(() {
          _saving = false;
          _error = f.userMessage;
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
          Text('Новый лимит', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          // Target type selector (Category / Group)
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'CATEGORY', label: Text('Категория')),
              ButtonSegment(value: 'GROUP', label: Text('Группа')),
            ],
            selected: {_targetType},
            onSelectionChanged: (s) => setState(() {
              _targetType = s.first;
              _targetId = null;
            }),
          ),
          const SizedBox(height: 12),
          // Scope selector: Personal / Family
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Личный')),
              ButtonSegment(value: true, label: Text('Семейный')),
            ],
            selected: {_shared},
            onSelectionChanged: (s) => setState(() => _shared = s.first),
          ),
          const SizedBox(height: 12),
          if (_targetType == 'CATEGORY')
            ref.watch(categoriesProvider('EXPENSE')).when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Ошибка категорий: $e'),
                  data: (cats) => DropdownButtonFormField<String>(
                    initialValue: _targetId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Категория',
                      border: OutlineInputBorder(),
                    ),
                    items: cats
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _targetId = v),
                  ),
                )
          else
            ref.watch(groupsProvider(Scope.personal)).when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Ошибка групп: $e'),
                  data: (groups) {
                    final expense =
                        groups.where((g) => g.type == 'EXPENSE').toList();
                    if (expense.isEmpty) {
                      return const Text(
                        'Нет групп расходов — создайте их в «Ещё → Группы»',
                      );
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: _targetId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Группа',
                        border: OutlineInputBorder(),
                      ),
                      items: expense
                          .map(
                            (g) => DropdownMenuItem(
                              value: g.id,
                              child: Text(g.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _targetId = v),
                    );
                  },
                ),
          const SizedBox(height: 12),
          HigTextField(
            controller: _amount,
            label: 'Месячный лимит',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [ThousandsSeparatorInputFormatter()],
          ),
          const SizedBox(height: 12),
          HigTextField(
            controller: _threshold,
            label: 'Порог уведомления, %',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'Уведомить, когда расходы достигнут ${_threshold.text.isEmpty ? '80' : _threshold.text}% лимита',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: HigColors.of(context).danger)),
          ],
          const SizedBox(height: 16),
          HigButton(label: 'Создать', loading: _saving, onPressed: _submit),
        ],
      ),
    );
  }
}
