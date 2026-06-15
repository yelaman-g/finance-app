import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/core/errors/failure_message.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/household/data/models/household_model.dart';
import 'package:aifb/features/household/presentation/providers/household_providers.dart';
import 'package:aifb/features/statistics/presentation/providers/statistics_providers.dart';
import 'package:aifb/shared/widgets/hig_button.dart';
import 'package:aifb/shared/widgets/hig_text_field.dart';
import 'package:aifb/shared/widgets/inset_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FamilyPage extends ConsumerWidget {
  const FamilyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hig = HigColors.of(context);
    final async = ref.watch(myHouseholdProvider);
    return Scaffold(
      backgroundColor: hig.pageBackground,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myHouseholdProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text('Семья'),
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
              data: (h) => h == null
                  ? SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _NoHousehold(
                            onChanged: () {
                              // После создания/вступления обновляем и семью,
                              // и разбивку по участникам (она могла закэшировать
                              // 409 «не в семье» на дашборде до вступления).
                              ref
                                ..invalidate(myHouseholdProvider)
                                ..invalidate(memberBreakdownProvider);
                            },
                          ),
                        ]),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _HouseholdView(
                            household: h,
                            onChanged: () {
                              ref
                                ..invalidate(myHouseholdProvider)
                                ..invalidate(memberBreakdownProvider);
                            },
                          ),
                        ]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoHousehold extends ConsumerStatefulWidget {
  const _NoHousehold({required this.onChanged});
  final VoidCallback onChanged;
  @override
  ConsumerState<_NoHousehold> createState() => _NoHouseholdState();
}

class _NoHouseholdState extends ConsumerState<_NoHousehold> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<Result<HouseholdModel>> Function() op) async {
    setState(() => _error = null);
    final result = await op();
    if (!mounted) return;
    if (result is Err<HouseholdModel>) {
      setState(() => _error = result.failure.userMessage);
    } else {
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);
    final repo = ref.read(householdRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InsetSection(
          header: 'Создать семью',
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HigTextField(
                    controller: _name,
                    label: 'Название семьи',
                  ),
                  const SizedBox(height: 12),
                  HigButton(
                    label: 'Создать',
                    onPressed: () => _run(() => repo.create(_name.text.trim())),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InsetSection(
          header: 'Вступить по коду',
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HigTextField(
                    controller: _code,
                    label: 'Код приглашения',
                  ),
                  const SizedBox(height: 12),
                  HigButton(
                    label: 'Вступить',
                    style: HigButtonStyle.tinted,
                    onPressed: () => _run(() => repo.join(_code.text.trim())),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: hig.danger, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _HouseholdView extends ConsumerWidget {
  const _HouseholdView({required this.household, required this.onChanged});
  final HouseholdModel household;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hig = HigColors.of(context);
    final repo = ref.read(householdRepositoryProvider);
    final breakdown = ref.watch(memberBreakdownProvider);
    final fmt = NumberFormat.decimalPattern();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (household.inviteCode != null) ...[
          InsetSection(
            header: 'Код приглашения',
            children: [
              InsetTile(
                title: household.inviteCode!,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      tooltip: 'Копировать код',
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: household.inviteCode!),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Код приглашения скопирован'),
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Обновить код',
                      onPressed: () async {
                        await repo.rotateCode();
                        onChanged();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        InsetSection(
          header: 'Участники',
          children: household.members.map((m) {
            return InsetTile(
              title: m.fullName,
              subtitle: m.role,
              trailing: household.isOwner && m.role != 'OWNER'
                  ? PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'remove') {
                          await repo.removeMember(m.userId);
                        } else {
                          await repo.changeRole(m.userId, action);
                        }
                        onChanged();
                      },
                      itemBuilder: (_) => [
                        if (m.role != 'ADULT')
                          const PopupMenuItem(
                            value: 'ADULT',
                            child: Text('Сделать ADULT'),
                          ),
                        if (m.role != 'CHILD')
                          const PopupMenuItem(
                            value: 'CHILD',
                            child: Text('Сделать CHILD'),
                          ),
                        if (m.role != 'GUEST')
                          const PopupMenuItem(
                            value: 'GUEST',
                            child: Text('Сделать GUEST'),
                          ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('Удалить'),
                        ),
                      ],
                    )
                  : null,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        InsetSection(
          header: 'Кто сколько потратил',
          children: [
            breakdown.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Ошибка: $e', style: TextStyle(color: hig.danger)),
              ),
              data: (rows) => rows.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Данных пока нет',
                        style: TextStyle(color: hig.secondaryLabel),
                      ),
                    )
                  : Column(
                      children: rows
                          .map(
                            (r) => InsetTile(
                              title: r.fullName,
                              trailing: Text(
                                '-${fmt.format(r.expense)}',
                                style: TextStyle(
                                  color: hig.secondaryLabel,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (household.isOwner)
          HigButton(
            label: 'Распустить семью',
            style: HigButtonStyle.plain,
            onPressed: () async {
              await repo.disband();
              onChanged();
            },
          )
        else
          HigButton(
            label: 'Выйти из семьи',
            style: HigButtonStyle.plain,
            onPressed: () async {
              await repo.leave();
              onChanged();
            },
          ),
      ],
    );
  }
}
