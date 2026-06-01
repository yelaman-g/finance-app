import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/categorization/presentation/providers/categorization_providers.dart';
import 'package:aifb/features/transactions/data/models/category_model.dart';
import 'package:aifb/features/transactions/data/models/transaction_model.dart';
import 'package:aifb/features/transactions/presentation/providers/finance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Модальная форма создания транзакции. Возвращает true при успехе.
Future<bool?> showTransactionForm(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _TransactionForm(),
  );
}

class _TransactionForm extends ConsumerStatefulWidget {
  const _TransactionForm();

  @override
  ConsumerState<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<_TransactionForm> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _type = 'EXPENSE';
  String? _categoryId;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;
  bool _shared = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0 || _categoryId == null) {
      setState(() => _error = 'Укажите сумму и категорию');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(financeRepositoryProvider).create(
          categoryId: _categoryId!,
          type: _type,
          amount: amount,
          occurredOn: _date,
          note: _note.text,
          shared: _shared,
        );
    if (!mounted) return;
    switch (result) {
      case Ok<dynamic>(value: final created):
        if (created is TransactionModel && created.budgetWarnings.isNotEmpty) {
          final w = created.budgetWarnings.first;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Бюджет «${w.targetName}» превышен (${w.status})'),
            ),
          );
        }
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
    final categoriesAsync = _shared
        ? ref.watch(familyCategoriesProvider(_type))
        : ref.watch(categoriesProvider(_type));
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Новая операция',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'EXPENSE', label: Text('Расход')),
              ButtonSegment(value: 'INCOME', label: Text('Доход')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() {
              _type = s.first;
              _categoryId = null;
            }),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            title: const Text('Семейная операция'),
            value: _shared,
            onChanged: (v) => setState(() {
              _shared = v;
              _categoryId = null;
            }),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Сумма',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          categoriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Ошибка категорий: $e'),
            data: (cats) => DropdownButtonFormField<String>(
              initialValue: _categoryId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Категория',
                border: OutlineInputBorder(),
              ),
              items: cats
                  .map(
                    (CategoryModel c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Дата: ${_date.toIso8601String().split('T').first}',
                ),
              ),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: const Text('Изменить'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: InputDecoration(
              labelText: 'Заметка (необязательно)',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.auto_awesome),
                tooltip: 'Подобрать категорию',
                onPressed: () async {
                  final result = await ref
                      .read(categorizationRepositoryProvider)
                      .suggest(note: _note.text, type: _type);
                  if (result is Ok<String?> && result.value != null) {
                    setState(() => _categoryId = result.value);
                  }
                },
              ),
            ),
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
                : const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
