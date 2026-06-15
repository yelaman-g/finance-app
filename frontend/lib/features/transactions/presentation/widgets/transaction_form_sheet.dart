import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/core/errors/failure_message.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/core/utils/thousands_formatter.dart';
import 'package:aifb/features/categorization/presentation/providers/categorization_providers.dart';
import 'package:aifb/features/transactions/data/models/category_model.dart';
import 'package:aifb/features/transactions/data/models/transaction_model.dart';
import 'package:aifb/features/transactions/presentation/providers/finance_providers.dart';
import 'package:aifb/shared/widgets/hig_button.dart';
import 'package:aifb/shared/widgets/hig_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Модальная форма создания транзакции. Возвращает true при успехе.
Future<bool?> showTransactionForm(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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
    final amount = double.tryParse(unformatAmount(_amount.text));
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
          _error = f.userMessage;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);
    final categoriesAsync = _shared
        ? ref.watch(familyCategoriesProvider(_type))
        : ref.watch(categoriesProvider(_type));
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
          // Handle bar
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
            'Новая операция',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: hig.label,
            ),
          ),
          const SizedBox(height: 16),
          // Type segment
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
          // Shared switch
          SwitchListTile(
            title: Text('Семейная операция', style: TextStyle(color: hig.label)),
            value: _shared,
            onChanged: (v) => setState(() {
              _shared = v;
              _categoryId = null;
            }),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          // Amount
          HigTextField(
            controller: _amount,
            label: 'Сумма',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [ThousandsSeparatorInputFormatter()],
          ),
          const SizedBox(height: 12),
          // Category dropdown
          categoriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(
              'Ошибка категорий: $e',
              style: TextStyle(color: hig.danger),
            ),
            data: (cats) => DropdownButtonFormField<String>(
              initialValue: _categoryId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Категория',
                filled: true,
                fillColor: hig.card,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: hig.separator),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: hig.accent, width: 1.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
          // Date row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Дата: ${_date.toIso8601String().split('T').first}',
                  style: TextStyle(fontSize: 15, color: hig.label),
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
          // Note + suggest button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: HigTextField(
                  controller: _note,
                  label: 'Заметка (необязательно)',
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Подобрать категорию',
                child: IconButton(
                  icon: const Icon(Icons.auto_awesome),
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
            ],
          ),
          // Error text
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: hig.danger, fontSize: 14),
            ),
          ],
          const SizedBox(height: 16),
          // Submit button
          HigButton(
            label: 'Сохранить',
            loading: _saving,
            onPressed: _saving ? null : _submit,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
