import 'package:aifb/features/categories/presentation/widgets/category_form_sheet.dart';
import 'package:aifb/features/transactions/presentation/providers/finance_providers.dart';
import 'package:aifb/shared/widgets/inset_section.dart';
import 'package:aifb/shared/widgets/large_title_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});
  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  String _type = 'EXPENSE';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(categoriesProvider(_type));
    return LargeTitleScaffold(
      title: 'Категории',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showCategoryForm(context, type: _type);
          if (created ?? false) ref.invalidate(categoriesProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Категория'),
      ),
      slivers: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'EXPENSE', label: Text('Расходы')),
            ButtonSegment(value: 'INCOME', label: Text('Доходы')),
          ],
          selected: {_type},
          onSelectionChanged: (s) => setState(() => _type = s.first),
        ),
        const SizedBox(height: 16),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Ошибка: $e'),
          data: (cats) {
            final own = cats.where((c) => !c.system).toList();
            final system = cats.where((c) => c.system).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (own.isNotEmpty)
                  InsetSection(
                    header: 'Мои категории',
                    children: own
                        .map(
                          (c) => InsetTile(
                            title: c.name,
                            onTap: () async {
                              final changed = await showCategoryForm(
                                context,
                                type: _type,
                                existing: c,
                              );
                              if (changed ?? false) {
                                ref.invalidate(categoriesProvider);
                              }
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await ref
                                    .read(financeRepositoryProvider)
                                    .deleteCategory(c.id);
                                ref.invalidate(categoriesProvider);
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                if (own.isNotEmpty) const SizedBox(height: 16),
                InsetSection(
                  header: 'Системные',
                  children:
                      system.map((c) => InsetTile(title: c.name)).toList(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
