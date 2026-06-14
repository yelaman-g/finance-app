import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/features/groups/presentation/providers/groups_providers.dart';
import 'package:aifb/shared/widgets/hig_button.dart';
import 'package:aifb/shared/widgets/hig_text_field.dart';
import 'package:aifb/shared/widgets/inset_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _groupTypeLabels = {
  'EXPENSE': 'Расходы',
  'INCOME': 'Доходы',
};

class GroupsPage extends ConsumerWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hig = HigColors.of(context);
    final async = ref.watch(groupsProvider(Scope.personal));
    return Scaffold(
      backgroundColor: hig.pageBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Новая группа'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(groupsProvider(Scope.personal).future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text('Группы'),
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
              data: (groups) {
                if (groups.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('Групп пока нет')),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverToBoxAdapter(
                    child: InsetSection(
                      children: groups.map((g) {
                        return InsetTile(
                          title: g.name,
                          subtitle: _groupTypeLabels[g.type] ?? g.type,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await ref
                                  .read(groupsRepositoryProvider)
                                  .delete(g.id);
                              ref.invalidate(groupsProvider(Scope.personal));
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
    final name = TextEditingController();
    var type = 'EXPENSE';
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Новая группа'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HigTextField(
                controller: name,
                label: 'Название',
                hint: 'например, Кафе и рестораны',
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'EXPENSE', label: Text('Расход')),
                  ButtonSegment(value: 'INCOME', label: Text('Доход')),
                ],
                selected: {type},
                onSelectionChanged: (s) => setState(() => type = s.first),
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
                if (name.text.trim().isEmpty) return;
                await ref
                    .read(groupsRepositoryProvider)
                    .create(name: name.text.trim(), type: type);
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
            ),
          ],
        ),
      ),
    );
    if (created ?? false) ref.invalidate(groupsProvider(Scope.personal));
  }
}
