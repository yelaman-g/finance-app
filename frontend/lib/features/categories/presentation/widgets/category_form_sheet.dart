import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/groups/presentation/providers/groups_providers.dart';
import 'package:aifb/features/transactions/data/models/category_model.dart';
import 'package:aifb/features/transactions/presentation/providers/finance_providers.dart';
import 'package:aifb/shared/widgets/hig_button.dart';
import 'package:aifb/shared/widgets/hig_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool?> showCategoryForm(
  BuildContext context, {
  required String type,
  CategoryModel? existing,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CategoryForm(type: type, existing: existing),
  );
}

class _CategoryForm extends ConsumerStatefulWidget {
  const _CategoryForm({required this.type, this.existing});
  final String type;
  final CategoryModel? existing;
  @override
  ConsumerState<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<_CategoryForm> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  String? _groupId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _groupId = widget.existing?.groupId;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Укажите название');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(financeRepositoryProvider);
    final result = widget.existing == null
        ? await repo.createCategory(
            name: _name.text.trim(),
            type: widget.type,
            groupId: _groupId,
          )
        : await repo.updateCategory(
            id: widget.existing!.id,
            name: _name.text.trim(),
            groupId: _groupId,
          );
    if (!mounted) return;
    switch (result) {
      case Ok<CategoryModel>():
        Navigator.of(context).pop(true);
      case Err<CategoryModel>(failure: final f):
        setState(() {
          _saving = false;
          _error = f.toString();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final groupsAsync = ref.watch(groupsProvider(Scope.personal));
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null ? 'Новая категория' : 'Изменить категорию',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          HigTextField(controller: _name, label: 'Название'),
          const SizedBox(height: 12),
          groupsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
            data: (groups) {
              final sameType =
                  groups.where((g) => g.type == widget.type).toList();
              if (sameType.isEmpty) return const SizedBox.shrink();
              return DropdownButtonFormField<String?>(
                initialValue: _groupId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Группа (необязательно)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    child: Text('Без группы'),
                  ),
                  ...sameType.map(
                    (g) => DropdownMenuItem<String?>(
                      value: g.id,
                      child: Text(g.name),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _groupId = v),
              );
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          HigButton(label: 'Сохранить', loading: _saving, onPressed: _submit),
        ],
      ),
    );
  }
}
