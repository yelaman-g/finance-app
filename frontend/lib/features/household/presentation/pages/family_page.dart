import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/household/data/models/household_model.dart';
import 'package:aifb/features/household/presentation/providers/household_providers.dart';
import 'package:aifb/features/statistics/presentation/providers/statistics_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FamilyPage extends ConsumerWidget {
  const FamilyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myHouseholdProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Семья')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (h) => h == null
            ? _NoHousehold(onChanged: () => ref.invalidate(myHouseholdProvider))
            : _HouseholdView(
                household: h,
                onChanged: () {
                  ref
                    ..invalidate(myHouseholdProvider)
                    ..invalidate(memberBreakdownProvider);
                },
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
    final result = await op();
    if (!mounted) return;
    if (result is Err<HouseholdModel>) {
      setState(() => _error = result.failure.toString());
    } else {
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(householdRepositoryProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Создать семью', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Название семьи',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => _run(() => repo.create(_name.text.trim())),
          child: const Text('Создать'),
        ),
        const Divider(height: 32),
        Text('Вступить по коду', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        TextField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Код приглашения',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => _run(() => repo.join(_code.text.trim())),
          child: const Text('Вступить'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
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
    final repo = ref.read(householdRepositoryProvider);
    final breakdown = ref.watch(memberBreakdownProvider);
    final fmt = NumberFormat.decimalPattern();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(household.name, style: Theme.of(context).textTheme.headlineSmall),
        if (household.inviteCode != null) ...[
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Код приглашения'),
              subtitle: Text(
                household.inviteCode!,
                style: const TextStyle(fontSize: 22, letterSpacing: 2),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Обновить код',
                onPressed: () async {
                  await repo.rotateCode();
                  onChanged();
                },
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text('Участники', style: Theme.of(context).textTheme.titleLarge),
        ...household.members.map(
          (m) => Card(
            child: ListTile(
              title: Text(m.fullName),
              subtitle: Text(m.role),
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
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'ADULT', child: Text('Сделать ADULT')),
                        PopupMenuItem(value: 'CHILD', child: Text('Сделать CHILD')),
                        PopupMenuItem(value: 'remove', child: Text('Удалить')),
                      ],
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Кто сколько потратил',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        breakdown.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => Text('Ошибка: $e'),
          data: (rows) => Column(
            children: rows
                .map(
                  (r) => ListTile(
                    title: Text(r.fullName),
                    trailing: Text('-${fmt.format(r.expense)}'),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        if (household.isOwner)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Распустить семью'),
            onPressed: () async {
              await repo.disband();
              onChanged();
            },
          )
        else
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Выйти из семьи'),
            onPressed: () async {
              await repo.leave();
              onChanged();
            },
          ),
      ],
    );
  }
}
