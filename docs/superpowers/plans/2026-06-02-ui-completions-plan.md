# План — UI-доработки: редактирование (лимиты/цели/правила) + экран категорий

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Достроить недостающий UI поверх готового бэкенда: редактирование лимита (сумма), цели (название/сумма/срок), правила (keyword/категория), и полноценный экран управления категориями (создание/правка/удаление + назначение группы).

**Architecture:** Чисто фронтовые доработки (Flutter). Backend PUT/POST/DELETE-эндпоинты уже есть (`PUT /budgets/{id}`, `PUT /goals/{id}`, `PUT /categorization/rules/{id}`, `POST/PUT/DELETE /categories`). Добавляем методы в data sources/репозитории и формы/экран в стиле HIG (`HigTextField`/`HigButton`/`InsetSection`/`InsetTile`/`HigColors`, large-title). Логика провайдеров/инвалидации — как в существующих фичах.

**Tech Stack:** Flutter 3.44, Riverpod, Dio, `very_good_analysis`; тесты — flutter_test + mocktail.

**Предусловие:** ветка `feature/hig-redesign` (актуальная, содержит всё). HIG-компоненты и фичи budgets/goals/categorization/transactions реализованы.

---

## Структура файлов

**Изменяемые (data layer):**
- `budgets/data/{budgets_data_source,budgets_repository}.dart` (+update)
- `goals/data/{goals_data_source,goals_repository}.dart` (+update)
- `categorization/data/{categorization_data_source,categorization_repository}.dart` (+update)
- `transactions/data/{finance_data_source,finance_repository}.dart` (+createCategory/updateCategory/deleteCategory)

**Изменяемые (UI):**
- `budgets/presentation/pages/budgets_page.dart` (edit-amount)
- `goals/presentation/widgets/goal_form_sheet.dart` (режим edit) + `goals/presentation/pages/goal_detail_page.dart` (действие «Изменить»)
- `categorization/presentation/pages/rules_page.dart` (edit-диалог)

**Создаваемые:**
- `transactions/presentation/providers/finance_providers.dart` — уже есть; добавим инвалидацию через существующий `categoriesProvider`.
- `features/categories/presentation/pages/categories_page.dart` — экран управления категориями
- `features/categories/presentation/widgets/category_form_sheet.dart` — форма создания/правки категории
- route `/categories-manage` + пункт в `more_page.dart`
- тесты: дополнить `test/features/budgets/budgets_repository_test.dart` (или новый) — проверка update маппинга

Команды — из `frontend/`. Гейт: `flutter analyze lib` 0 errors/warnings (info ок), `flutter test` зелёный.

---

## Task 1: Data layer — update-методы и CRUD категорий

**Files:** budgets/goals/categorization data sources + repos; finance data source + repo; repo test.

- [ ] **Step 1: budgets** — в `budgets_data_source.dart` добавить:
```dart
  Future<BudgetModel> update(String id, Map<String, dynamic> body) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '${ApiEndpoints.budgets}/$id',
      data: body,
    );
    return BudgetModel.fromJson(unwrapObject(res.data));
  }
```
В `budgets_repository.dart` добавить:
```dart
  Future<Result<BudgetModel>> update({
    required String id,
    required double amount,
  }) =>
      _guard(() => _ds.update(id, {'amount': amount}));
```

- [ ] **Step 2: goals** — в `goals_data_source.dart` добавить:
```dart
  Future<GoalModel> update(String id, Map<String, dynamic> body) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '${ApiEndpoints.goals}/$id',
      data: body,
    );
    return GoalModel.fromJson(unwrapObject(res.data));
  }
```
В `goals_repository.dart` добавить (использует существующий `_date`):
```dart
  Future<Result<GoalModel>> update({
    required String id,
    required String name,
    required double targetAmount,
    DateTime? deadline,
    String? icon,
    String? color,
  }) =>
      _guard(() => _ds.update(id, {
            'name': name,
            'targetAmount': targetAmount,
            if (deadline != null) 'deadline': _date(deadline),
            if (icon != null) 'icon': icon,
            if (color != null) 'color': color,
          },),);
```

- [ ] **Step 3: categorization** — в `categorization_data_source.dart` добавить:
```dart
  Future<RuleModel> update(String id, Map<String, dynamic> body) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '${ApiEndpoints.categorizationRules}/$id',
      data: body,
    );
    return RuleModel.fromJson(unwrapObject(res.data));
  }
```
В `categorization_repository.dart` добавить:
```dart
  Future<Result<RuleModel>> update({
    required String id,
    required String keyword,
    required String categoryId,
  }) =>
      _guard(() => _ds.update(id, {'keyword': keyword, 'categoryId': categoryId}));
```

- [ ] **Step 4: categories CRUD** — в `finance_data_source.dart` добавить:
```dart
  Future<CategoryModel> createCategory(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.categories,
      data: body,
    );
    return CategoryModel.fromJson(unwrapObject(res.data));
  }

  Future<CategoryModel> updateCategory(String id, Map<String, dynamic> body) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '${ApiEndpoints.categories}/$id',
      data: body,
    );
    return CategoryModel.fromJson(unwrapObject(res.data));
  }

  Future<void> deleteCategory(String id) async {
    await _dio.delete<void>('${ApiEndpoints.categories}/$id');
  }
```
В `finance_repository.dart` добавить:
```dart
  Future<Result<CategoryModel>> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
    String? groupId,
    bool shared = false,
  }) =>
      _guard(() => _ds.createCategory({
            'name': name,
            'type': type,
            'shared': shared,
            if (icon != null) 'icon': icon,
            if (color != null) 'color': color,
            if (groupId != null) 'groupId': groupId,
          }),);

  Future<Result<CategoryModel>> updateCategory({
    required String id,
    required String name,
    String? icon,
    String? color,
    String? groupId,
  }) =>
      _guard(() => _ds.updateCategory(id, {
            'name': name,
            if (icon != null) 'icon': icon,
            if (color != null) 'color': color,
            if (groupId != null) 'groupId': groupId,
          }),);

  Future<Result<void>> deleteCategory(String id) =>
      _guard(() => _ds.deleteCategory(id));
```

- [ ] **Step 5: тест маппинга update** — дополнить `frontend/test/features/budgets/budgets_repository_test.dart` тестом (или создать `..._update_test.dart`):
```dart
  test('update returns Ok with budget', () async {
    when(() => ds.update('b1', {'amount': 500.0})).thenAnswer((_) async =>
        const BudgetModel(
          id: 'b1', targetType: 'CATEGORY', targetId: 'c1', targetName: 'Еда',
          amount: 500, spent: 0, percentage: 0, status: 'OK', shared: false,
        ));
    final result = await repo.update(id: 'b1', amount: 500);
    expect(result, isA<Ok<BudgetModel>>());
    expect((result as Ok<BudgetModel>).value.amount, 500);
  });
```
(добавьте `import` уже есть; `_MockDs` уже мокает `BudgetsDataSource` — у него теперь есть `update`.)

- [ ] **Step 6: Анализ + тесты + commit**
```bash
cd frontend && flutter analyze lib/features/budgets lib/features/goals lib/features/categorization lib/features/transactions test/features/budgets && flutter test test/features/budgets/budgets_repository_test.dart
git add frontend/lib/features/budgets/data frontend/lib/features/goals/data frontend/lib/features/categorization/data frontend/lib/features/transactions/data frontend/test/features/budgets
git commit -m "feat(ui): data layer — update лимита/цели/правила + CRUD категорий"
```

---

## Task 2: Редактирование лимита (сумма)

**Files:** `budgets/presentation/pages/budgets_page.dart`.

- [ ] **Step 1: READ** `budgets_page.dart` (ConsumerWidget; список лимитов в `InsetSection`, у каждой строки — Row с именем/суммой/delete `IconButton`; есть `budgetsRepositoryProvider`, `budgetsProvider(Scope.personal)`).
- [ ] **Step 2:** Добавить редактирование суммы: на строке лимита сделать всю строку нажимаемой (`InkWell`) → открывает диалог изменения суммы. Добавить приватный метод в `BudgetsPage`:
```dart
  Future<void> _editAmount(BuildContext context, WidgetRef ref, String id, double current) async {
    final controller = TextEditingController(text: current.toStringAsFixed(0));
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Изменить лимит'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Сумма'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx, double.tryParse(controller.text.replaceAll(',', '.')),),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    await ref.read(budgetsRepositoryProvider).update(id: id, amount: amount);
    ref.invalidate(budgetsProvider(Scope.personal));
  }
```
Обернуть содержимое строки лимита в `InkWell(onTap: () => _editAmount(context, ref, b.id, b.amount), child: <Padding...>)` (или добавить edit-`IconButton` рядом с delete). Сохранить delete как есть.
- [ ] **Step 3:** `cd frontend && flutter analyze lib/features/budgets` — 0 ошибок.
- [ ] **Step 4: Commit**
```bash
git add frontend/lib/features/budgets/presentation
git commit -m "feat(ui): редактирование суммы лимита"
```

---

## Task 3: Редактирование цели

**Files:** `goals/presentation/widgets/goal_form_sheet.dart`, `goals/presentation/pages/goal_detail_page.dart`.

- [ ] **Step 1: READ** оба файла + `goal_model.dart` (поля `id,name,targetAmount,deadline,icon,color`).
- [ ] **Step 2: goal_form_sheet** — поддержать режим редактирования. Изменить `showGoalForm` и `_GoalForm`, добавив необязательный `GoalModel? existing`:
```dart
Future<bool?> showGoalForm(BuildContext context, {GoalModel? existing}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _GoalForm(existing: existing),
  );
}
```
В `_GoalForm`/state: принять `final GoalModel? existing;`; в initState предзаполнить контроллеры (`_name.text = existing!.name`, `_target.text = existing!.targetAmount.toStringAsFixed(0)`, `_deadline = existing!.deadline`) если `existing != null`; заголовок «Изменить цель» vs «Новая цель»; в `_submit` если `existing != null` → `ref.read(goalsRepositoryProvider).update(id: existing!.id, name:, targetAmount:, deadline:, icon: existing!.icon, color: existing!.color)`, иначе `.create(...)` как раньше. (import `goal_model.dart`.) Сохранить тумблер «Семейная» только в режиме создания (при edit scope не меняем — скрыть свитч если `existing != null`).
- [ ] **Step 3: goal_detail_page** — добавить в app bar (или `LargeTitleScaffold.actions`) действие «Изменить»:
```dart
actions: [
  IconButton(
    icon: const Icon(Icons.edit_outlined),
    onPressed: () async {
      // нужен текущий GoalModel: если на экране есть только goalId — подгрузить через goalsRepositoryProvider.get(goalId),
      // либо передать GoalModel в GoalDetailPage. Простейше: загрузить get(goalId) перед открытием формы.
      final res = await ref.read(goalsRepositoryProvider).get(goalId);
      if (res is Ok<GoalModel> && context.mounted) {
        final changed = await showGoalForm(context, existing: res.value);
        if ((changed ?? false)) {
          ref..invalidate(goalContributionsProvider(goalId))
             ..invalidate(goalsProvider(Scope.personal));
        }
      }
    },
  ),
],
```
(import `Ok`, `GoalModel`, `Scope`, `goalsProvider`, `showGoalForm`. Если `goal_detail_page` не на `LargeTitleScaffold` с `actions` — добавить кнопку в его app bar / соответствующее место; READ и адаптировать.)
- [ ] **Step 4:** `cd frontend && flutter analyze lib/features/goals` — 0 ошибок.
- [ ] **Step 5: Commit**
```bash
git add frontend/lib/features/goals/presentation
git commit -m "feat(ui): редактирование цели (форма в режиме edit + действие на экране цели)"
```

---

## Task 4: Редактирование правила

**Files:** `categorization/presentation/pages/rules_page.dart`.

- [ ] **Step 1: READ** `rules_page.dart` (есть приватный `_create(context, ref)` с диалогом keyword+категория; список — `InsetTile`, trailing=delete).
- [ ] **Step 2:** Обобщить диалог: добавить приватный `_edit(context, ref, RuleModel rule)` (или параметризовать `_create` необязательным `RuleModel? existing`). Прелзаполнить keyword и выбранную категорию; заголовок «Изменить правило»; на submit → `ref.read(categorizationRepositoryProvider).update(id: rule.id, keyword:, categoryId:)`; затем `ref.invalidate(rulesProvider)`. Сделать `InsetTile` нажимаемым (`onTap: () => _edit(context, ref, r)`), delete оставить trailing.
(Категории для выбора — `ref.read(categoriesProvider('EXPENSE').future)` как в `_create`; import `RuleModel`.)
- [ ] **Step 3:** `cd frontend && flutter analyze lib/features/categorization` — 0 ошибок.
- [ ] **Step 4: Commit**
```bash
git add frontend/lib/features/categorization/presentation
git commit -m "feat(ui): редактирование правила категоризации"
```

---

## Task 5: Экран управления категориями (CRUD + группа)

**Files:** `features/categories/presentation/pages/categories_page.dart`, `features/categories/presentation/widgets/category_form_sheet.dart`; `routes.dart`; `app_router.dart`; `more_page.dart`.

Используем существующие: `categoriesProvider(type)` (личные категории), `financeRepositoryProvider` (новые createCategory/updateCategory/deleteCategory из Task 1), `groupsProvider(Scope.personal)` для выбора группы, `CategoryModel{id,name,type,system,icon,color,groupId}`.

- [ ] **Step 1: Форма** `category_form_sheet.dart`:
```dart
import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/groups/presentation/providers/groups_providers.dart';
import 'package:aifb/features/transactions/data/models/category_model.dart';
import 'package:aifb/features/transactions/presentation/providers/finance_providers.dart';
import 'package:aifb/shared/widgets/hig_button.dart';
import 'package:aifb/shared/widgets/hig_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Создание/редактирование личной категории. type — 'EXPENSE'/'INCOME'.
Future<bool?> showCategoryForm(BuildContext context,
    {required String type, CategoryModel? existing}) {
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
            name: _name.text.trim(), type: widget.type, groupId: _groupId)
        : await repo.updateCategory(
            id: widget.existing!.id, name: _name.text.trim(), groupId: _groupId);
    if (!mounted) return;
    switch (result) {
      case Ok<dynamic>():
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final groupsAsync = ref.watch(groupsProvider(Scope.personal));
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.existing == null ? 'Новая категория' : 'Изменить категорию',
              style: Theme.of(context).textTheme.titleLarge),
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
                    labelText: 'Группа (необязательно)', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Без группы')),
                  ...sameType.map((g) =>
                      DropdownMenuItem<String?>(value: g.id, child: Text(g.name))),
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
```

- [ ] **Step 2: Экран** `categories_page.dart`:
```dart
import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/features/categories/presentation/widgets/category_form_sheet.dart';
import 'package:aifb/features/transactions/data/models/category_model.dart';
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
          if ((created ?? false)) ref.invalidate(categoriesProvider);
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
                        .map((c) => InsetTile(
                              title: c.name,
                              onTap: () async {
                                final changed = await showCategoryForm(context,
                                    type: _type, existing: c);
                                if ((changed ?? false)) {
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
                            ),)
                        .toList(),
                  ),
                const SizedBox(height: 16),
                InsetSection(
                  header: 'Системные',
                  children: system
                      .map((c) => InsetTile(title: c.name))
                      .toList(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
```
(Системные категории — только показ, без правки/удаления, что соответствует бэку: PUT/DELETE системной → 403.)

- [ ] **Step 3: Маршрут.** В `routes.dart` (App shell) добавить `static const categoriesManage = _Route('categories-manage', '/categories-manage');`. В `app_router.dart` добавить импорт `import '../../features/categories/presentation/pages/categories_page.dart';` и top-level `GoRoute`:
```dart
      GoRoute(
        path: AppRoutes.categoriesManage.path,
        name: AppRoutes.categoriesManage.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const CategoriesPage(),
        ),
      ),
```
- [ ] **Step 4: Пункт в «Ещё».** В `more_page.dart` в `InsetSection «Управление»` добавить `InsetTile`:
```dart
            InsetTile(
              title: 'Категории',
              leading: const Icon(Icons.category_rounded),
              onTap: () => context.push(AppRoutes.categoriesManage.path),
            ),
```
- [ ] **Step 5: Анализ + тесты + commit**
```bash
cd frontend && flutter analyze lib && flutter test
git add frontend/lib/features/categories frontend/lib/app/router/routes.dart frontend/lib/app/router/app_router.dart frontend/lib/features/more
git commit -m "feat(ui): экран управления категориями (CRUD + назначение группы) + пункт в «Ещё»"
```

---

## Task 6: Ручная проверка

- [ ] **Step 1:** `flutter build web --no-tree-shake-icons` — собирается. Поднять стек, проверить: правка суммы лимита; правка цели (название/сумма/срок); правка правила; экран «Ещё → Категории» — создать свою категорию (с группой), переименовать, удалить; системные не редактируются.

---

## Self-review (выполнено при написании плана)

- **Покрытие:** редактирование лимита (Task 2), цели (Task 3), правила (Task 4); экран категорий CRUD + группа (Task 5); под них — data-layer методы (Task 1). Все backend-эндпоинты существуют (PUT /budgets|/goals|/categorization/rules, POST/PUT/DELETE /categories).
- **Плейсхолдеры:** нет — полный код для data layer/форм/экрана; правки существующих экранов — точечные с конкретными сниппетами и инструкцией READ+adapt (формы редактирования = переиспользование существующих диалогов в режиме edit).
- **Согласованность типов:** новые методы `budgetsRepository.update({id,amount})`, `goalsRepository.update({id,name,targetAmount,deadline,icon,color})`, `categorizationRepository.update({id,keyword,categoryId})`, `financeRepository.createCategory/updateCategory/deleteCategory` совпадают с вызовами в формах. `categoriesProvider(type)` инвалидируется целиком (`ref.invalidate(categoriesProvider)`). `CategoryModel.system` используется для скрытия правки системных.
- **Заметка по scope:** экран категорий управляет ЛИЧНЫМИ категориями (создание `shared:false`); семейные категории — вне объёма этой доработки (можно добавить позже toggle). Группы для выбора фильтруются по совпадению типа.
