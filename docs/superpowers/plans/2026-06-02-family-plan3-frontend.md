# План 3 — Frontend: Семейный бюджет

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Подключить фронт к семейному бюджету: фича `household` (создать/вступить/участники/роли/код), переключатель «Личное | Семья» на дашборде (провайдеры параметризуются scope), тумблер «Семейное» в формах операции/цели, карточка разбивки «кто сколько потратил».

**Architecture:** Слои как в существующих фичах. Новые модели — обычные Dart-классы (без freezed). Существующие провайдеры финансов/статистики/целей переводятся на `FutureProvider.family<…, Scope>` (scope: enum PERSONAL/FAMILY). Data sources получают `scope`-параметр и `shared` в create. Новая фича `household`.

**Tech Stack:** Flutter 3.44, Riverpod, go_router, Dio, intl; тесты — flutter_test + mocktail. NEW-файлы: `package:aifb/...` импорты, satisfy `very_good_analysis`; правка существующих — сохранять их стиль.

**Предусловие:** Планы 1–2 семейного бюджета (backend) реализованы; эндпоинты `/households/*`, `scope`/`shared`, `/statistics/by-member` работают. Существующий фронт финансов/целей/статистики на месте.

---

## Структура файлов

**Создаваемые — общее:** `lib/core/domain/scope.dart` (enum Scope + `query` getter)

**Создаваемые — household:**
- `lib/features/household/data/models/household_model.dart` (HouseholdModel, MemberModel)
- `lib/features/household/data/household_data_source.dart`
- `lib/features/household/data/household_repository.dart`
- `lib/features/household/presentation/providers/household_providers.dart`
- `lib/features/household/presentation/pages/family_page.dart`
- `test/features/household/household_repository_test.dart`

**Создаваемые — статистика by-member:** `lib/features/statistics/data/models/member_breakdown_model.dart`

**Изменяемые:**
- `lib/features/transactions/data/finance_data_source.dart` + `finance_repository.dart` + `providers/finance_providers.dart`
- `lib/features/goals/data/goals_data_source.dart` + `goals_repository.dart` + `providers/goals_providers.dart`
- `lib/features/statistics/data/statistics_data_source.dart` + `statistics_repository.dart` + `providers/statistics_providers.dart`
- `lib/features/transactions/presentation/widgets/transaction_form_sheet.dart`
- `lib/features/goals/presentation/widgets/goal_form_sheet.dart`
- `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- `lib/core/network/api_endpoints.dart`, `lib/app/router/routes.dart`, `lib/app/router/app_router.dart`

Команды — из `frontend/`. Гейт: NEW-файлы без analyzer-ошибок; `flutter test` зелёный.

---

## Task 1: Household — модели, data source, репозиторий, провайдеры

**Files:** см. «household» выше + endpoint.

- [ ] **Step 1: Эндпоинты + enum Scope**

In `lib/core/network/api_endpoints.dart` add inside class:
```dart
  // Households
  static const String households = '/households';

  // Statistics (family)
  static const String statByMember = '/statistics/by-member';
```

Create `lib/core/domain/scope.dart`:
```dart
enum Scope {
  personal,
  family;

  String get query => this == Scope.family ? 'FAMILY' : 'PERSONAL';
}
```

- [ ] **Step 2: Модели**

Create `lib/features/household/data/models/household_model.dart`:
```dart
class MemberModel {
  const MemberModel({required this.userId, required this.fullName, required this.role});

  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
        userId: json['userId'] as String,
        fullName: json['fullName'] as String,
        role: json['role'] as String,
      );

  final String userId;
  final String fullName;
  final String role;
}

class HouseholdModel {
  const HouseholdModel({
    required this.id,
    required this.name,
    required this.myRole,
    required this.members,
    this.inviteCode,
  });

  factory HouseholdModel.fromJson(Map<String, dynamic> json) => HouseholdModel(
        id: json['id'] as String,
        name: json['name'] as String,
        myRole: json['myRole'] as String,
        inviteCode: json['inviteCode'] as String?,
        members: (json['members'] as List)
            .map((e) => MemberModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String id;
  final String name;
  final String myRole;
  final String? inviteCode;
  final List<MemberModel> members;

  bool get isOwner => myRole == 'OWNER';
}
```

- [ ] **Step 3: Data source**

Create `lib/features/household/data/household_data_source.dart`:
```dart
import 'package:aifb/core/network/api_endpoints.dart';
import 'package:aifb/core/network/envelope.dart';
import 'package:aifb/features/household/data/models/household_model.dart';
import 'package:dio/dio.dart';

class HouseholdDataSource {
  HouseholdDataSource(this._dio);
  final Dio _dio;

  Future<HouseholdModel> me() async {
    final res =
        await _dio.get<Map<String, dynamic>>('${ApiEndpoints.households}/me');
    return HouseholdModel.fromJson(unwrapObject(res.data));
  }

  Future<HouseholdModel> create(String name) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.households,
      data: {'name': name},
    );
    return HouseholdModel.fromJson(unwrapObject(res.data));
  }

  Future<HouseholdModel> join(String inviteCode) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '${ApiEndpoints.households}/join',
      data: {'inviteCode': inviteCode},
    );
    return HouseholdModel.fromJson(unwrapObject(res.data));
  }

  Future<HouseholdModel> changeRole(String userId, String role) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '${ApiEndpoints.households}/members/$userId/role',
      data: {'role': role},
    );
    return HouseholdModel.fromJson(unwrapObject(res.data));
  }

  Future<void> removeMember(String userId) async {
    await _dio.delete<void>('${ApiEndpoints.households}/members/$userId');
  }

  Future<void> leave() async {
    await _dio.post<void>('${ApiEndpoints.households}/leave');
  }

  Future<void> disband() async {
    await _dio.delete<void>(ApiEndpoints.households);
  }

  Future<HouseholdModel> rotateCode() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '${ApiEndpoints.households}/rotate-code',
    );
    return HouseholdModel.fromJson(unwrapObject(res.data));
  }
}
```

- [ ] **Step 4: Падающий тест репозитория**

Create `test/features/household/household_repository_test.dart`:
```dart
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/household/data/household_data_source.dart';
import 'package:aifb/features/household/data/household_repository.dart';
import 'package:aifb/features/household/data/models/household_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDs extends Mock implements HouseholdDataSource {}

void main() {
  late _MockDs ds;
  late HouseholdRepository repo;

  setUp(() {
    ds = _MockDs();
    repo = HouseholdRepository(ds);
  });

  test('create returns Ok with household', () async {
    when(() => ds.create('Семья')).thenAnswer((_) async => const HouseholdModel(
          id: 'h1', name: 'Семья', myRole: 'OWNER', members: [], inviteCode: 'ABC',
        ));
    final result = await repo.create('Семья');
    expect(result, isA<Ok<HouseholdModel>>());
    expect((result as Ok<HouseholdModel>).value.isOwner, isTrue);
  });

  test('me maps notFound error to Err', () async {
    when(ds.me).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/households/me'),
      response: Response(
        requestOptions: RequestOptions(path: '/households/me'),
        statusCode: 404,
        data: const {'error': {'code': 'NOT_FOUND', 'message': 'нет семьи'}},
      ),
    ));
    final result = await repo.me();
    expect(result, isA<Err<HouseholdModel>>());
  });
}
```
Run `cd frontend && flutter test test/features/household/household_repository_test.dart` → FAIL (no repo).

- [ ] **Step 5: Репозиторий**

Create `lib/features/household/data/household_repository.dart`:
```dart
import 'package:aifb/core/errors/error_mapper.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/household/data/household_data_source.dart';
import 'package:aifb/features/household/data/models/household_model.dart';

class HouseholdRepository {
  HouseholdRepository(this._ds);
  final HouseholdDataSource _ds;

  Future<Result<HouseholdModel>> me() => _guard(_ds.me);
  Future<Result<HouseholdModel>> create(String name) => _guard(() => _ds.create(name));
  Future<Result<HouseholdModel>> join(String code) => _guard(() => _ds.join(code));
  Future<Result<HouseholdModel>> changeRole(String userId, String role) =>
      _guard(() => _ds.changeRole(userId, role));
  Future<Result<void>> removeMember(String userId) => _guard(() => _ds.removeMember(userId));
  Future<Result<void>> leave() => _guard(_ds.leave);
  Future<Result<void>> disband() => _guard(_ds.disband);
  Future<Result<HouseholdModel>> rotateCode() => _guard(_ds.rotateCode);

  Future<Result<T>> _guard<T>(Future<T> Function() task) async {
    try {
      return Result.ok(await task());
    } catch (e) {
      return Result.err(mapDioError(e));
    }
  }
}
```
Run the test again → 2 pass.

- [ ] **Step 6: Провайдеры**

Create `lib/features/household/presentation/providers/household_providers.dart`:
```dart
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/core/network/dio_client.dart';
import 'package:aifb/features/household/data/household_data_source.dart';
import 'package:aifb/features/household/data/household_repository.dart';
import 'package:aifb/features/household/data/models/household_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final householdDataSourceProvider = Provider<HouseholdDataSource>((ref) {
  return HouseholdDataSource(ref.watch(dioProvider));
});

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return HouseholdRepository(ref.watch(householdDataSourceProvider));
});

/// Текущая семья или null (если 404 — пользователь не в семье).
final myHouseholdProvider = FutureProvider.autoDispose<HouseholdModel?>((ref) async {
  final result = await ref.watch(householdRepositoryProvider).me();
  return switch (result) {
    Ok<HouseholdModel>(value: final v) => v,
    Err<HouseholdModel>() => null,
  };
});
```

- [ ] **Step 7: Анализ + commit**
```bash
cd frontend && flutter analyze lib/features/household lib/core/domain/scope.dart test/features/household
git add frontend/lib/core/domain/scope.dart frontend/lib/core/network/api_endpoints.dart frontend/lib/features/household frontend/test/features/household
git commit -m "feat(frontend): household — модели, data source, репозиторий, провайдеры"
```

---

## Task 2: Scope в финансах/статистике/целях + by-member

**Files:** finance/goals/statistics data sources + repos + providers; statistics member model.

- [ ] **Step 1: Data sources — scope/shared**

`finance_data_source.dart`:
- `categories(String? type, {String scope = 'PERSONAL'})` — add `'scope': scope` to queryParameters.
- `transactions({... , String scope = 'PERSONAL'})` — add `'scope': scope`.
- `create(Map body)` — без изменений (body уже формирует repo, добавим `shared`).

`statistics_data_source.dart`:
- `summary({String scope = 'PERSONAL'})`, `byCategory(String type, {String scope='PERSONAL'})`, `trend({String scope='PERSONAL'})` — add `'scope': scope` query param.
- add `byMember()` → GET `ApiEndpoints.statByMember`, unwrapList → `MemberBreakdownModel`.

`goals_data_source.dart`:
- `list({String scope = 'PERSONAL'})` — add `'scope': scope`.

- [ ] **Step 2: Member model**

Create `lib/features/statistics/data/models/member_breakdown_model.dart`:
```dart
class MemberBreakdownModel {
  const MemberBreakdownModel({
    required this.userId,
    required this.fullName,
    required this.income,
    required this.expense,
  });

  factory MemberBreakdownModel.fromJson(Map<String, dynamic> json) =>
      MemberBreakdownModel(
        userId: json['userId'] as String,
        fullName: json['fullName'] as String,
        income: (json['income'] as num).toDouble(),
        expense: (json['expense'] as num).toDouble(),
      );

  final String userId;
  final String fullName;
  final double income;
  final double expense;
}
```

- [ ] **Step 3: Repos — проброс scope/shared**

- `FinanceRepository.categories({String? type, Scope scope = Scope.personal})` → `_ds.categories(type, scope: scope.query)`.
- `FinanceRepository.transactions({..., Scope scope = Scope.personal})` → проброс `scope: scope.query`.
- `FinanceRepository.create({..., bool shared = false})` → добавить `'shared': shared` в тело.
- `StatisticsRepository.summary({Scope scope = Scope.personal})`, `byCategory(type, {scope})`, `trend({scope})` → проброс. Добавить `byMember()` → `_guard(() => _ds.byMember())`.
- `GoalsRepository.list({Scope scope = Scope.personal})` и `create({..., bool shared = false})`.
(Импортировать `package:aifb/core/domain/scope.dart` там, где нужен `Scope`.)

- [ ] **Step 4: Провайдеры — параметризовать scope**

- `finance_providers.dart`: `transactionsProvider` → `FutureProvider.autoDispose.family<PageResult<TransactionModel>, Scope>((ref, scope) async { ... transactions(scope: scope, size: 50) ... })`. `categoriesProvider` оставить family по `String?` type, но добавить параллельный вызов с family scope в форме (форма сама решает scope — см. Task 4; для простоты в форме вызывается репозиторий напрямую с нужным scope, провайдер не трогаем).
- `statistics_providers.dart`: `summaryProvider`/`expenseByCategoryProvider`/`trendProvider` → `.family<…, Scope>`. Добавить `memberBreakdownProvider` (FutureProvider.autoDispose<List<MemberBreakdownModel>>) → `repo.byMember()`.
- `goals_providers.dart`: `goalsProvider` → `.family<List<GoalModel>, Scope>`.

Пример для summary:
```dart
final summaryProvider =
    FutureProvider.autoDispose.family<SummaryModel, Scope>((ref, scope) async {
  final result = await ref.watch(statisticsRepositoryProvider).summary(scope: scope);
  return switch (result) {
    Ok<SummaryModel>(value: final v) => v,
    Err<SummaryModel>(failure: final f) => throw Exception(f.toString()),
  };
});
```

- [ ] **Step 5: Обновить существующие вызовы провайдеров**

- `transactions_page.dart`: `ref.watch(transactionsProvider)` → `ref.watch(transactionsProvider(Scope.personal))`; аналогично `ref.invalidate`/`ref.refresh`. (Личный список операций.)
- `goals_page.dart`: `goalsProvider` → `goalsProvider(Scope.personal)` во всех обращениях.
- (Дашборд переведём в Task 4.)

- [ ] **Step 6: Анализ + commit**
```bash
cd frontend && flutter analyze lib/features/transactions lib/features/goals lib/features/statistics
git add frontend/lib/features/transactions frontend/lib/features/goals frontend/lib/features/statistics
git commit -m "feat(frontend): scope в финансах/статистике/целях + by-member + shared в create"
```

---

## Task 3: Экран «Семья» + маршрут

**Files:** family_page.dart; routes.dart; app_router.dart.

- [ ] **Step 1: Экран «Семья»**

Create `lib/features/household/presentation/pages/family_page.dart`:
```dart
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
                  ref..invalidate(myHouseholdProvider)
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
              labelText: 'Название семьи', border: OutlineInputBorder()),
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
              labelText: 'Код приглашения', border: OutlineInputBorder()),
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
              subtitle: Text(household.inviteCode!,
                  style: const TextStyle(fontSize: 22, letterSpacing: 2)),
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
        ...household.members.map((m) => Card(
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
            )),
        const SizedBox(height: 16),
        Text('Кто сколько потратил', style: Theme.of(context).textTheme.titleLarge),
        breakdown.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
          error: (e, _) => Text('Ошибка: $e'),
          data: (rows) => Column(
            children: rows
                .map((r) => ListTile(
                      title: Text(r.fullName),
                      trailing: Text('-${fmt.format(r.expense)}'),
                    ))
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
```

- [ ] **Step 2: Маршрут**

`routes.dart` → в App shell добавить `static const family = _Route('family', '/family');`.
`app_router.dart` → импорт `import '../../features/household/presentation/pages/family_page.dart';` (относительный, как в файле) и GoRoute:
```dart
      GoRoute(
        path: AppRoutes.family.path,
        name: AppRoutes.family.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const FamilyPage(),
        ),
      ),
```

- [ ] **Step 3: Анализ + commit**
```bash
cd frontend && flutter analyze lib/features/household lib/app/router
git add frontend/lib/features/household/presentation/pages/family_page.dart frontend/lib/app/router/routes.dart frontend/lib/app/router/app_router.dart
git commit -m "feat(frontend): экран «Семья» (создать/вступить/участники/роли/код/разбивка) + маршрут"
```

---

## Task 4: Дашборд — переключатель scope; формы — тумблер «Семейное»

**Files:** dashboard_page.dart; transaction_form_sheet.dart; goal_form_sheet.dart.

- [ ] **Step 1: Тумблер «Семейное» в форме операции**

In `transaction_form_sheet.dart`:
- add field `bool _shared = false;`
- add a `SwitchListTile` (под сегментом типа): «Семейная операция» → `_shared` (по умолчанию off).
- when `_shared` true, категории берём из семейного scope: change `ref.watch(categoriesProvider(_type))` to load family categories. Simplest: call repository directly. Replace category load with a `FutureProvider.family` keyed by `(type, shared)` OR inside build: `final catsAsync = _shared ? ref.watch(familyCategoriesProvider(_type)) : ref.watch(categoriesProvider(_type));`. Add to `finance_providers.dart`:
```dart
final familyCategoriesProvider =
    FutureProvider.autoDispose.family<List<CategoryModel>, String?>((ref, type) async {
  final result = await ref.watch(financeRepositoryProvider)
      .categories(type: type, scope: Scope.family);
  return switch (result) {
    Ok<List<CategoryModel>>(value: final v) => v,
    Err<List<CategoryModel>>(failure: final f) => throw Exception(f.toString()),
  };
});
```
(import Scope in finance_providers.) Reset `_categoryId = null` when toggling `_shared`.
- pass `shared: _shared` to `repo.create(...)`.
- after success the dashboard/lists should refresh — handled by their own invalidation.

- [ ] **Step 2: Тумблер «Семейная цель» в форме цели**

In `goal_form_sheet.dart`: add `bool _shared = false;` + `SwitchListTile('Семейная цель')`; pass `shared: _shared` to `repo.create(...)`. (CHILD получит 403 от бэка — показываем ошибку в форме, что уже реализовано через `_error`.)

- [ ] **Step 3: Переключатель scope на дашборде**

Convert `dashboard_page.dart` to hold scope state. Replace `class DashboardPage extends ConsumerWidget` with `ConsumerStatefulWidget` holding `Scope _scope = Scope.personal;` (import `package:aifb/core/domain/scope.dart` — but file uses relative imports; use `../../../../core/domain/scope.dart`).
- Add a segmented control at the top of the sliver list:
```dart
SegmentedButton<Scope>(
  segments: const [
    ButtonSegment(value: Scope.personal, label: Text('Личное')),
    ButtonSegment(value: Scope.family, label: Text('Семья')),
  ],
  selected: {_scope},
  onSelectionChanged: (s) => setState(() => _scope = s.first),
),
```
- Parameterize provider reads by `_scope`:
  `ref.watch(summaryProvider(_scope))`, `ref.watch(trendProvider(_scope))`,
  `ref.watch(transactionsProvider(_scope))`, `ref.watch(goalsProvider(_scope))`.
- In family scope, add a member-breakdown card after goals:
```dart
if (_scope == Scope.family)
  ref.watch(memberBreakdownProvider).maybeWhen(
    data: (rows) => _MemberBreakdownCard(rows: rows),
    orElse: () => const SizedBox.shrink(),
  ),
```
  Add a small `_MemberBreakdownCard` widget (list of fullName → expense) in the same file.
- «View all» у операций ведёт на `/transactions`; добавить кнопку/иконку перехода на `/family` в топ-баре (рядом с admin): `_IconBubble(icon: Icons.group_rounded, onTap: () => context.push(AppRoutes.family.path))`.

- [ ] **Step 4: Анализ всего проекта**
```bash
cd frontend && flutter analyze lib
```
Expected: 0 errors/warnings (pre-existing info-хинты допустимы).

- [ ] **Step 5: Все фронт-тесты**
```bash
cd frontend && flutter test
```
Expected: все тесты passed (household repo + существующие).

- [ ] **Step 6: Commit**
```bash
git add frontend/lib/features/dashboard frontend/lib/features/transactions frontend/lib/features/goals
git commit -m "feat(frontend): переключатель Личное|Семья на дашборде + тумблеры Семейное в формах + разбивка по участникам"
```

---

## Task 5: Ручная проверка стека

- [ ] **Step 1: Поднять стек и проверить сценарий**
```bash
docker start aifb-db 2>/dev/null || true
( cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew bootRun & )
cd frontend && flutter run -d chrome --web-port 3000
```
Проверить: на `/family` создать семью → виден код; вторым аккаунтом (другой браузер/инкогнито) вступить по коду; на дашборде переключить «Семья»; добавить семейную операцию (тумблер «Семейная»); увидеть её и разбивку «кто потратил» у обоих участников; сменить роль участника на CHILD и убедиться, что он не создаёт семейные цели.

---

## Self-review (выполнено при написании плана)

- **Покрытие спеки:** фича `household` (create/join/me/роли/удаление/выход/роспуск/код) + экран «Семья»; переключатель «Личное|Семья» на дашборде через параметризацию провайдеров `Scope`; тумблеры «Семейное» в формах операции/цели; карточка разбивки по участникам (by-member); маршрут `/family`. Соответствует секции спеки «Frontend».
- **Плейсхолдеры:** для NEW-файлов код приведён полностью; для правок существующих — точные инструкции с кодом фрагментов и именами провайдеров. Объёмные формы/дашборд описаны конкретными добавлениями (тумблер, сегмент, параметризация), без «доделать сами».
- **Согласованность типов:** `Scope` (`core/domain/scope.dart`, `.query`) используется в data sources (как строка), repos и провайдерах (как enum); `HouseholdModel`/`MemberModel`/`MemberBreakdownModel` едины между data source, репозиторием, провайдерами и экранами. Параметризованные провайдеры (`summaryProvider(scope)`, `transactionsProvider(scope)`, `goalsProvider(scope)`) согласованы с их новыми вызовами в `transactions_page`/`goals_page`/`dashboard_page` (Task 2 Step 5 + Task 4).
- **Заметка:** `myHouseholdProvider` трактует ошибку `me()` (404) как «нет семьи» (null) — экран показывает форму создания/вступления.
