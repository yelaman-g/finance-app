import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/features/categorization/data/models/rule_model.dart';
import 'package:aifb/features/categorization/presentation/providers/categorization_providers.dart';
import 'package:aifb/features/transactions/presentation/providers/finance_providers.dart';
import 'package:aifb/shared/widgets/hig_button.dart';
import 'package:aifb/shared/widgets/hig_text_field.dart';
import 'package:aifb/shared/widgets/inset_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RulesPage extends ConsumerWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hig = HigColors.of(context);
    final async = ref.watch(rulesProvider);
    return Scaffold(
      backgroundColor: hig.pageBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Новое правило'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(rulesProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text('Правила'),
              backgroundColor: hig.pageBackground,
              surfaceTintColor: Colors.transparent,
            ),
            async.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Ошибка: $e')),
              ),
              data: (rules) {
                if (rules.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('Правил пока нет')),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverToBoxAdapter(
                    child: InsetSection(
                      children: rules.map((r) {
                        return InsetTile(
                          title: '«${r.keyword}» → ${r.categoryName}',
                          onTap: () => _edit(context, ref, r),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await ref
                                  .read(categorizationRepositoryProvider)
                                  .delete(r.id);
                              ref.invalidate(rulesProvider);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final keyword = TextEditingController();
    String? categoryId;
    final catsAsync = await ref.read(categoriesProvider('EXPENSE').future);
    if (!context.mounted) return;
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Новое правило'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HigTextField(
                controller: keyword,
                label: 'Ключевое слово',
                hint: 'например, Магнит',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: categoryId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Категория'),
                items: catsAsync
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => categoryId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            HigButton(
              label: 'Создать',
              onPressed: () async {
                if (keyword.text.trim().isEmpty || categoryId == null) return;
                await ref
                    .read(categorizationRepositoryProvider)
                    .create(
                      keyword: keyword.text.trim(),
                      categoryId: categoryId!,
                    );
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
            ),
          ],
        ),
      ),
    );
    if (created ?? false) ref.invalidate(rulesProvider);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, RuleModel rule) async {
    final keyword = TextEditingController(text: rule.keyword);
    String? categoryId = rule.categoryId;
    final catsAsync = await ref.read(categoriesProvider('EXPENSE').future);
    if (!context.mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Изменить правило'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HigTextField(
                controller: keyword,
                label: 'Ключевое слово',
                hint: 'например, Магнит',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: categoryId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Категория'),
                items: catsAsync
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => categoryId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            HigButton(
              label: 'Сохранить',
              onPressed: () async {
                if (keyword.text.trim().isEmpty || categoryId == null) return;
                await ref
                    .read(categorizationRepositoryProvider)
                    .update(
                      id: rule.id,
                      keyword: keyword.text.trim(),
                      categoryId: categoryId!,
                    );
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
            ),
          ],
        ),
      ),
    );
    if (saved ?? false) ref.invalidate(rulesProvider);
  }
}
