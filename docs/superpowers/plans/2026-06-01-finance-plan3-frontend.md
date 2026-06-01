# План 3 — Frontend: интеграция финансового ядра и целей

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Подключить Flutter-фронт к новым API (категории, транзакции, статистика, цели): новые фичи `transactions`/`goals`/`statistics`, экраны списков и форм, и замена mock-данных на дашборде реальными (баланс, график трат, последние операции, прогресс целей).

**Architecture:** Слои как в существующих фичах: `data` (Dio data source + модель + repository), `presentation` (Riverpod-провайдеры + страницы). Новые модели — обычные иммутабельные Dart-классы с ручными `fromJson` (без freezed/json_serializable — чтобы не зависеть от build_runner для нового кода). Переиспользуем `Result`/`Ok`/`Err` (`core/network/api_result.dart`), `mapDioError` (`core/errors/error_mapper.dart`) и `dioProvider` (`core/network/dio_client.dart`). Бэкенд-конверт `{data, error, meta}` разворачивается общим хелпером.

**Tech Stack:** Flutter ≥ 3.22, Dart ≥ 3.4, Riverpod, go_router, Dio, intl, fl_chart; тесты — flutter_test + mocktail.

**Предусловие:** Планы 1 и 2 реализованы; бэкенд отвечает на `/api/v1/categories|transactions|statistics|goals`. Все frontend-команды запускаются из `frontend/`. Если Flutter не установлен — установить SDK и выполнить `flutter pub get` перед стартом.

---

## Структура файлов

**Изменяемые:**
- `lib/core/network/api_endpoints.dart` — новые пути.
- `lib/app/router/routes.dart` — маршруты `transactions`, `goals`.
- `lib/app/router/app_router.dart` — `GoRoute` для новых экранов.
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` — реальные данные.
- `lib/features/dashboard/presentation/widgets/balance_card.dart` — параметры income/expense.
- `lib/features/dashboard/presentation/widgets/spending_chart_card.dart` — принимает данные.

**Создаваемые — общие:**
- `lib/core/network/envelope.dart` — разворачивание конверта `{data,...}`.
- `lib/core/utils/hex_color.dart` — парсинг hex-цвета.

**Создаваемые — фича `transactions`:**
- `lib/features/transactions/data/models/category_model.dart`
- `lib/features/transactions/data/models/transaction_model.dart`
- `lib/features/transactions/data/models/page_result.dart`
- `lib/features/transactions/data/finance_data_source.dart`
- `lib/features/transactions/data/finance_repository.dart`
- `lib/features/transactions/presentation/providers/finance_providers.dart`
- `lib/features/transactions/presentation/pages/transactions_page.dart`
- `lib/features/transactions/presentation/widgets/transaction_form_sheet.dart`

**Создаваемые — фича `statistics`:**
- `lib/features/statistics/data/models/statistics_models.dart`
- `lib/features/statistics/data/statistics_data_source.dart`
- `lib/features/statistics/data/statistics_repository.dart`
- `lib/features/statistics/presentation/providers/statistics_providers.dart`

**Создаваемые — фича `goals`:**
- `lib/features/goals/data/models/goal_model.dart`
- `lib/features/goals/data/goals_data_source.dart`
- `lib/features/goals/data/goals_repository.dart`
- `lib/features/goals/presentation/providers/goals_providers.dart`
- `lib/features/goals/presentation/pages/goals_page.dart`
- `lib/features/goals/presentation/pages/goal_detail_page.dart`
- `lib/features/goals/presentation/widgets/goal_form_sheet.dart`

**Создаваемые — тесты:**
- `test/features/transactions/finance_repository_test.dart`
- `test/features/goals/goals_repository_test.dart`

---

## Task 1: Общие утилиты, эндпоинты, модели

**Files:**
- Create: `lib/core/network/envelope.dart`
- Create: `lib/core/utils/hex_color.dart`
- Modify: `lib/core/network/api_endpoints.dart`
- Create: `lib/features/transactions/data/models/category_model.dart`
- Create: `lib/features/transactions/data/models/transaction_model.dart`
- Create: `lib/features/transactions/data/models/page_result.dart`
- Create: `lib/features/statistics/data/models/statistics_models.dart`
- Create: `lib/features/goals/data/models/goal_model.dart`

- [ ] **Step 1: Создать хелпер конверта**

Create `lib/core/network/envelope.dart`:
```dart
import 'package:dio/dio.dart';

/// Разворачивает объект из конверта бэка `{ "data": {...} }`.
Map<String, dynamic> unwrapObject(Map<String, dynamic>? body) {
  final data = body?['data'];
  if (data is Map<String, dynamic>) return data;
  throw DioException(
    requestOptions: RequestOptions(),
    message: 'Malformed envelope (expected object)',
  );
}

/// Разворачивает массив из конверта бэка `{ "data": [...] }`.
List<dynamic> unwrapList(Map<String, dynamic>? body) {
  final data = body?['data'];
  if (data is List) return data;
  throw DioException(
    requestOptions: RequestOptions(),
    message: 'Malformed envelope (expected array)',
  );
}
```

- [ ] **Step 2: Создать парсер hex-цвета**

Create `lib/core/utils/hex_color.dart`:
```dart
import 'package:flutter/material.dart';

/// Парсит "#RRGGBB" / "#AARRGGBB" в [Color]. При ошибке — [fallback].
Color hexToColor(String? hex, {Color fallback = const Color(0xFF2F6BFF)}) {
  if (hex == null || hex.isEmpty) return fallback;
  var value = hex.replaceAll('#', '').trim();
  if (value.length == 6) value = 'FF$value';
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? fallback : Color(parsed);
}
```

- [ ] **Step 3: Добавить эндпоинты**

В `lib/core/network/api_endpoints.dart` добавить внутри класса `ApiEndpoints` после блока Admin:
```dart
  // Categories
  static const String categories = '/categories';

  // Transactions
  static const String transactions = '/transactions';

  // Statistics
  static const String statSummary = '/statistics/summary';
  static const String statByCategory = '/statistics/by-category';
  static const String statTrend = '/statistics/trend';

  // Goals
  static const String goals = '/goals';
```

- [ ] **Step 4: Создать модель категории**

Create `lib/features/transactions/data/models/category_model.dart`:
```dart
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.system,
    this.icon,
    this.color,
  });

  final String id;
  final String name;
  final String type; // INCOME | EXPENSE
  final bool system;
  final String? icon;
  final String? color;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        system: json['system'] as bool? ?? false,
        icon: json['icon'] as String?,
        color: json['color'] as String?,
      );
}
```

- [ ] **Step 5: Создать модель транзакции и страницы**

Create `lib/features/transactions/data/models/transaction_model.dart`:
```dart
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.occurredOn,
    this.categoryName,
    this.categoryColor,
    this.categoryIcon,
    this.note,
  });

  final String id;
  final String categoryId;
  final String type; // INCOME | EXPENSE
  final double amount;
  final DateTime occurredOn;
  final String? categoryName;
  final String? categoryColor;
  final String? categoryIcon;
  final String? note;

  bool get isIncome => type == 'INCOME';

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String,
        type: json['type'] as String,
        amount: (json['amount'] as num).toDouble(),
        occurredOn: DateTime.parse(json['occurredOn'] as String),
        categoryName: json['categoryName'] as String?,
        categoryColor: json['categoryColor'] as String?,
        categoryIcon: json['categoryIcon'] as String?,
        note: json['note'] as String?,
      );
}
```

Create `lib/features/transactions/data/models/page_result.dart`:
```dart
class PageResult<T> {
  const PageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
    required this.hasNext,
  });

  final List<T> items;
  final int page;
  final int size;
  final int total;
  final bool hasNext;

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) =>
      PageResult<T>(
        items: (json['items'] as List)
            .map((e) => itemFromJson(e as Map<String, dynamic>))
            .toList(),
        page: json['page'] as int,
        size: json['size'] as int,
        total: json['total'] as int,
        hasNext: json['hasNext'] as bool,
      );
}
```

- [ ] **Step 6: Создать модели статистики**

Create `lib/features/statistics/data/models/statistics_models.dart`:
```dart
class SummaryModel {
  const SummaryModel({
    required this.income,
    required this.expense,
    required this.net,
  });

  final double income;
  final double expense;
  final double net;

  factory SummaryModel.fromJson(Map<String, dynamic> json) => SummaryModel(
        income: (json['income'] as num).toDouble(),
        expense: (json['expense'] as num).toDouble(),
        net: (json['net'] as num).toDouble(),
      );
}

class CategoryBreakdownModel {
  const CategoryBreakdownModel({
    required this.categoryId,
    required this.name,
    required this.total,
    required this.percentage,
    this.color,
  });

  final String categoryId;
  final String name;
  final double total;
  final double percentage;
  final String? color;

  factory CategoryBreakdownModel.fromJson(Map<String, dynamic> json) =>
      CategoryBreakdownModel(
        categoryId: json['categoryId'] as String,
        name: json['name'] as String,
        total: (json['total'] as num).toDouble(),
        percentage: (json['percentage'] as num).toDouble(),
        color: json['color'] as String?,
      );
}

class TrendPointModel {
  const TrendPointModel({
    required this.month,
    required this.income,
    required this.expense,
  });

  final String month; // YYYY-MM
  final double income;
  final double expense;

  factory TrendPointModel.fromJson(Map<String, dynamic> json) => TrendPointModel(
        month: json['month'] as String,
        income: (json['income'] as num).toDouble(),
        expense: (json['expense'] as num).toDouble(),
      );
}
```

- [ ] **Step 7: Создать модели целей**

Create `lib/features/goals/data/models/goal_model.dart`:
```dart
class GoalModel {
  const GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.percentage,
    required this.status,
    this.deadline,
    this.icon,
    this.color,
  });

  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final double percentage;
  final String status; // ACTIVE | COMPLETED | ARCHIVED
  final DateTime? deadline;
  final String? icon;
  final String? color;

  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
        id: json['id'] as String,
        name: json['name'] as String,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        savedAmount: (json['savedAmount'] as num).toDouble(),
        percentage: (json['percentage'] as num).toDouble(),
        status: json['status'] as String,
        deadline: json['deadline'] == null
            ? null
            : DateTime.parse(json['deadline'] as String),
        icon: json['icon'] as String?,
        color: json['color'] as String?,
      );
}

class ContributionModel {
  const ContributionModel({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.contributedOn,
    this.note,
  });

  final String id;
  final String goalId;
  final double amount;
  final DateTime contributedOn;
  final String? note;

  factory ContributionModel.fromJson(Map<String, dynamic> json) =>
      ContributionModel(
        id: json['id'] as String,
        goalId: json['goalId'] as String,
        amount: (json['amount'] as num).toDouble(),
        contributedOn: DateTime.parse(json['contributedOn'] as String),
        note: json['note'] as String?,
      );
}
```

- [ ] **Step 8: Проверить статанализ**

Run: `cd frontend && flutter analyze lib/core lib/features/transactions/data lib/features/statistics/data lib/features/goals/data`
Expected: `No issues found!`

- [ ] **Step 9: Commit**

```bash
git add frontend/lib/core/network/envelope.dart frontend/lib/core/utils/hex_color.dart frontend/lib/core/network/api_endpoints.dart frontend/lib/features/transactions/data/models frontend/lib/features/statistics/data/models frontend/lib/features/goals/data/models
git commit -m "feat(frontend): эндпоинты, конверт-хелпер и модели финансов/статистики/целей"
```

---

## Task 2: Транзакции — data source, репозиторий, провайдеры

**Files:**
- Create: `lib/features/transactions/data/finance_data_source.dart`
- Create: `lib/features/transactions/data/finance_repository.dart`
- Create: `lib/features/transactions/presentation/providers/finance_providers.dart`
- Test: `test/features/transactions/finance_repository_test.dart`

- [ ] **Step 1: Создать data source**

Create `lib/features/transactions/data/finance_data_source.dart`:
```dart
import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/envelope.dart';
import 'models/category_model.dart';
import 'models/page_result.dart';
import 'models/transaction_model.dart';

/// Чистый транспорт к /categories и /transactions. Бросает [DioException].
class FinanceDataSource {
  FinanceDataSource(this._dio);
  final Dio _dio;

  Future<List<CategoryModel>> categories(String? type) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.categories,
      queryParameters: {if (type != null) 'type': type},
    );
    return unwrapList(res.data)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PageResult<TransactionModel>> transactions({
    String? type,
    String? categoryId,
    DateTime? from,
    DateTime? to,
    int page = 0,
    int size = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.transactions,
      queryParameters: {
        if (type != null) 'type': type,
        if (categoryId != null) 'categoryId': categoryId,
        if (from != null) 'from': _date(from),
        if (to != null) 'to': _date(to),
        'page': page,
        'size': size,
      },
    );
    return PageResult.fromJson(unwrapObject(res.data), TransactionModel.fromJson);
  }

  Future<TransactionModel> create(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.transactions,
      data: body,
    );
    return TransactionModel.fromJson(unwrapObject(res.data));
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('${ApiEndpoints.transactions}/$id');
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
```

- [ ] **Step 2: Написать падающий тест репозитория**

Create `test/features/transactions/finance_repository_test.dart`:
```dart
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/transactions/data/finance_data_source.dart';
import 'package:aifb/features/transactions/data/finance_repository.dart';
import 'package:aifb/features/transactions/data/models/category_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements FinanceDataSource {}

void main() {
  late _MockDataSource ds;
  late FinanceRepository repo;

  setUp(() {
    ds = _MockDataSource();
    repo = FinanceRepository(ds);
  });

  test('categories returns Ok with mapped list', () async {
    when(() => ds.categories('EXPENSE')).thenAnswer((_) async => const [
          CategoryModel(id: '1', name: 'Еда', type: 'EXPENSE', system: true),
        ]);

    final result = await repo.categories(type: 'EXPENSE');

    expect(result, isA<Ok<List<CategoryModel>>>());
    final value = (result as Ok<List<CategoryModel>>).value;
    expect(value.single.name, 'Еда');
  });

  test('categories maps DioException to Err', () async {
    when(() => ds.categories(any())).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/categories')),
    );

    final result = await repo.categories(type: 'EXPENSE');

    expect(result, isA<Err<List<CategoryModel>>>());
  });
}
```

- [ ] **Step 3: Запустить тест — убедиться, что НЕ компилируется/падает**

Run: `cd frontend && flutter test test/features/transactions/finance_repository_test.dart`
Expected: FAIL — `FinanceRepository` ещё не создан.

- [ ] **Step 4: Создать репозиторий**

Create `lib/features/transactions/data/finance_repository.dart`:
```dart
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_result.dart';
import 'finance_data_source.dart';
import 'models/category_model.dart';
import 'models/page_result.dart';
import 'models/transaction_model.dart';

class FinanceRepository {
  FinanceRepository(this._ds);
  final FinanceDataSource _ds;

  Future<Result<List<CategoryModel>>> categories({String? type}) =>
      _guard(() => _ds.categories(type));

  Future<Result<PageResult<TransactionModel>>> transactions({
    String? type,
    String? categoryId,
    DateTime? from,
    DateTime? to,
    int page = 0,
    int size = 20,
  }) =>
      _guard(() => _ds.transactions(
            type: type,
            categoryId: categoryId,
            from: from,
            to: to,
            page: page,
            size: size,
          ));

  Future<Result<TransactionModel>> create({
    required String categoryId,
    required String type,
    required double amount,
    required DateTime occurredOn,
    String? note,
  }) =>
      _guard(() => _ds.create({
            'categoryId': categoryId,
            'type': type,
            'amount': amount,
            'occurredOn': _date(occurredOn),
            if (note != null && note.isNotEmpty) 'note': note,
          }));

  Future<Result<void>> delete(String id) => _guard(() => _ds.delete(id));

  Future<Result<T>> _guard<T>(Future<T> Function() task) async {
    try {
      return Result.ok(await task());
    } catch (e) {
      return Result.err(mapDioError(e));
    }
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
```

- [ ] **Step 5: Запустить тест — убедиться, что проходит**

Run: `cd frontend && flutter test test/features/transactions/finance_repository_test.dart`
Expected: PASS — 2 теста.

- [ ] **Step 6: Создать провайдеры**

Create `lib/features/transactions/presentation/providers/finance_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/finance_data_source.dart';
import '../../data/finance_repository.dart';
import '../../data/models/category_model.dart';
import '../../data/models/page_result.dart';
import '../../data/models/transaction_model.dart';

final financeDataSourceProvider = Provider<FinanceDataSource>((ref) {
  return FinanceDataSource(ref.watch(dioProvider));
});

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(ref.watch(financeDataSourceProvider));
});

/// Категории по типу (INCOME/EXPENSE или все при null).
final categoriesProvider =
    FutureProvider.family<List<CategoryModel>, String?>((ref, type) async {
  final result = await ref.watch(financeRepositoryProvider).categories(type: type);
  return switch (result) {
    Ok<List<CategoryModel>>(value: final v) => v,
    Err<List<CategoryModel>>(failure: final f) => throw Exception(f.toString()),
  };
});

/// Список транзакций (первая страница). Инвалидация — после создания/удаления.
final transactionsProvider =
    FutureProvider.autoDispose<PageResult<TransactionModel>>((ref) async {
  final result =
      await ref.watch(financeRepositoryProvider).transactions(size: 50);
  return switch (result) {
    Ok<PageResult<TransactionModel>>(value: final v) => v,
    Err<PageResult<TransactionModel>>(failure: final f) =>
      throw Exception(f.toString()),
  };
});
```

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/features/transactions/data/finance_data_source.dart frontend/lib/features/transactions/data/finance_repository.dart frontend/lib/features/transactions/presentation/providers/finance_providers.dart test/features/transactions/finance_repository_test.dart
git commit -m "feat(frontend): data source, репозиторий и провайдеры транзакций с тестом"
```

---

## Task 3: Транзакции — экран списка и форма создания + маршруты

**Files:**
- Create: `lib/features/transactions/presentation/widgets/transaction_form_sheet.dart`
- Create: `lib/features/transactions/presentation/pages/transactions_page.dart`
- Modify: `lib/app/router/routes.dart`
- Modify: `lib/app/router/app_router.dart`

- [ ] **Step 1: Создать форму создания транзакции**

Create `lib/features/transactions/presentation/widgets/transaction_form_sheet.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_result.dart';
import '../../data/models/category_model.dart';
import '../providers/finance_providers.dart';

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
        );
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
    final categoriesAsync = ref.watch(categoriesProvider(_type));
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Новая операция',
              style: Theme.of(context).textTheme.titleLarge),
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
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Сумма', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          categoriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Ошибка категорий: $e'),
            data: (cats) => DropdownButtonFormField<String>(
              initialValue: _categoryId,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Категория', border: OutlineInputBorder()),
              items: cats
                  .map((CategoryModel c) =>
                      DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('Дата: ${_date.toIso8601String().split('T').first}'),
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
            decoration: const InputDecoration(
                labelText: 'Заметка (необязательно)',
                border: OutlineInputBorder()),
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
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Создать экран списка транзакций**

Create `lib/features/transactions/presentation/pages/transactions_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/finance_providers.dart';
import '../widgets/transaction_form_sheet.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(transactionsProvider);
    final fmt = NumberFormat.decimalPattern();
    return Scaffold(
      appBar: AppBar(title: const Text('Операции')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showTransactionForm(context);
          if (created == true) ref.invalidate(transactionsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(transactionsProvider.future),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 80),
            Center(child: Text('Ошибка: $e')),
          ]),
          data: (page) {
            if (page.items.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Center(child: Text('Пока нет операций')),
              ]);
            }
            return ListView.separated(
              itemCount: page.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final t = page.items[i];
                final sign = t.isIncome ? '+' : '-';
                return Dismissible(
                  key: ValueKey(t.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    await ref.read(financeRepositoryProvider).delete(t.id);
                    ref.invalidate(transactionsProvider);
                  },
                  child: ListTile(
                    title: Text(t.categoryName ?? '—'),
                    subtitle: Text(
                      '${t.occurredOn.toIso8601String().split('T').first}'
                      '${t.note != null ? ' · ${t.note}' : ''}',
                    ),
                    trailing: Text(
                      '$sign${fmt.format(t.amount)}',
                      style: TextStyle(
                        color: t.isIncome ? Colors.green : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Добавить маршруты в `routes.dart`**

В `lib/app/router/routes.dart` в секцию `// App shell` добавить:
```dart
  static const transactions = _Route('transactions', '/transactions');
  static const goals = _Route('goals', '/goals');
```

- [ ] **Step 4: Подключить экран в `app_router.dart`**

В `lib/app/router/app_router.dart`:

(а) добавить импорт после импорта `dashboard_page.dart`:
```dart
import '../../features/transactions/presentation/pages/transactions_page.dart';
```

(б) в список `routes:` добавить (рядом с другими `GoRoute`):
```dart
      GoRoute(
        path: AppRoutes.transactions.path,
        name: AppRoutes.transactions.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const TransactionsPage(),
        ),
      ),
```

(в) заменить существующий `analytics`-маршрут так, чтобы кнопка «View all» вела на список операций: оставить маршрут `analytics` как есть; на дашборде (Task 6) кнопка будет вести на `AppRoutes.transactions`.

- [ ] **Step 5: Проверить анализ и сборку**

Run: `cd frontend && flutter analyze lib/features/transactions lib/app/router`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/transactions/presentation frontend/lib/app/router/routes.dart frontend/lib/app/router/app_router.dart
git commit -m "feat(frontend): экран операций, форма создания и маршрут"
```

---

## Task 4: Цели — data source, репозиторий, провайдеры, экраны

**Files:**
- Create: `lib/features/goals/data/goals_data_source.dart`
- Create: `lib/features/goals/data/goals_repository.dart`
- Create: `lib/features/goals/presentation/providers/goals_providers.dart`
- Create: `lib/features/goals/presentation/widgets/goal_form_sheet.dart`
- Create: `lib/features/goals/presentation/pages/goals_page.dart`
- Create: `lib/features/goals/presentation/pages/goal_detail_page.dart`
- Test: `test/features/goals/goals_repository_test.dart`
- Modify: `lib/app/router/app_router.dart`

- [ ] **Step 1: Создать data source**

Create `lib/features/goals/data/goals_data_source.dart`:
```dart
import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/envelope.dart';
import 'models/goal_model.dart';

class GoalsDataSource {
  GoalsDataSource(this._dio);
  final Dio _dio;

  Future<List<GoalModel>> list() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.goals);
    return unwrapList(res.data)
        .map((e) => GoalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GoalModel> get(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('${ApiEndpoints.goals}/$id');
    return GoalModel.fromJson(unwrapObject(res.data));
  }

  Future<GoalModel> create(Map<String, dynamic> body) async {
    final res =
        await _dio.post<Map<String, dynamic>>(ApiEndpoints.goals, data: body);
    return GoalModel.fromJson(unwrapObject(res.data));
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('${ApiEndpoints.goals}/$id');
  }

  Future<List<ContributionModel>> contributions(String goalId) async {
    final res = await _dio
        .get<Map<String, dynamic>>('${ApiEndpoints.goals}/$goalId/contributions');
    return unwrapList(res.data)
        .map((e) => ContributionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ContributionModel> addContribution(
      String goalId, Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '${ApiEndpoints.goals}/$goalId/contributions',
      data: body,
    );
    return ContributionModel.fromJson(unwrapObject(res.data));
  }
}
```

- [ ] **Step 2: Написать падающий тест репозитория**

Create `test/features/goals/goals_repository_test.dart`:
```dart
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/goals/data/goals_data_source.dart';
import 'package:aifb/features/goals/data/goals_repository.dart';
import 'package:aifb/features/goals/data/models/goal_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGoalsDs extends Mock implements GoalsDataSource {}

void main() {
  late _MockGoalsDs ds;
  late GoalsRepository repo;

  setUp(() {
    ds = _MockGoalsDs();
    repo = GoalsRepository(ds);
  });

  test('list returns Ok with goals', () async {
    when(ds.list).thenAnswer((_) async => const [
          GoalModel(
            id: 'g1',
            name: 'Отпуск',
            targetAmount: 1000,
            savedAmount: 250,
            percentage: 25,
            status: 'ACTIVE',
          ),
        ]);

    final result = await repo.list();

    expect(result, isA<Ok<List<GoalModel>>>());
    expect((result as Ok<List<GoalModel>>).value.single.percentage, 25);
  });

  test('list maps error to Err', () async {
    when(ds.list).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/goals')),
    );

    final result = await repo.list();

    expect(result, isA<Err<List<GoalModel>>>());
  });
}
```

- [ ] **Step 3: Запустить тест — убедиться, что падает**

Run: `cd frontend && flutter test test/features/goals/goals_repository_test.dart`
Expected: FAIL — `GoalsRepository` ещё не создан.

- [ ] **Step 4: Создать репозиторий**

Create `lib/features/goals/data/goals_repository.dart`:
```dart
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_result.dart';
import 'goals_data_source.dart';
import 'models/goal_model.dart';

class GoalsRepository {
  GoalsRepository(this._ds);
  final GoalsDataSource _ds;

  Future<Result<List<GoalModel>>> list() => _guard(_ds.list);

  Future<Result<GoalModel>> get(String id) => _guard(() => _ds.get(id));

  Future<Result<GoalModel>> create({
    required String name,
    required double targetAmount,
    DateTime? deadline,
    String? icon,
    String? color,
  }) =>
      _guard(() => _ds.create({
            'name': name,
            'targetAmount': targetAmount,
            if (deadline != null) 'deadline': _date(deadline),
            if (icon != null) 'icon': icon,
            if (color != null) 'color': color,
          }));

  Future<Result<void>> delete(String id) => _guard(() => _ds.delete(id));

  Future<Result<List<ContributionModel>>> contributions(String goalId) =>
      _guard(() => _ds.contributions(goalId));

  Future<Result<ContributionModel>> addContribution({
    required String goalId,
    required double amount,
    required DateTime contributedOn,
    String? note,
  }) =>
      _guard(() => _ds.addContribution(goalId, {
            'amount': amount,
            'contributedOn': _date(contributedOn),
            if (note != null && note.isNotEmpty) 'note': note,
          }));

  Future<Result<T>> _guard<T>(Future<T> Function() task) async {
    try {
      return Result.ok(await task());
    } catch (e) {
      return Result.err(mapDioError(e));
    }
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
```

- [ ] **Step 5: Запустить тест — убедиться, что проходит**

Run: `cd frontend && flutter test test/features/goals/goals_repository_test.dart`
Expected: PASS — 2 теста.

- [ ] **Step 6: Создать провайдеры**

Create `lib/features/goals/presentation/providers/goals_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/goals_data_source.dart';
import '../../data/goals_repository.dart';
import '../../data/models/goal_model.dart';

final goalsDataSourceProvider = Provider<GoalsDataSource>((ref) {
  return GoalsDataSource(ref.watch(dioProvider));
});

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepository(ref.watch(goalsDataSourceProvider));
});

final goalsProvider = FutureProvider.autoDispose<List<GoalModel>>((ref) async {
  final result = await ref.watch(goalsRepositoryProvider).list();
  return switch (result) {
    Ok<List<GoalModel>>(value: final v) => v,
    Err<List<GoalModel>>(failure: final f) => throw Exception(f.toString()),
  };
});

final goalContributionsProvider =
    FutureProvider.autoDispose.family<List<ContributionModel>, String>(
        (ref, goalId) async {
  final result = await ref.watch(goalsRepositoryProvider).contributions(goalId);
  return switch (result) {
    Ok<List<ContributionModel>>(value: final v) => v,
    Err<List<ContributionModel>>(failure: final f) => throw Exception(f.toString()),
  };
});
```

- [ ] **Step 7: Создать форму цели**

Create `lib/features/goals/presentation/widgets/goal_form_sheet.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_result.dart';
import '../providers/goals_providers.dart';

Future<bool?> showGoalForm(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _GoalForm(),
  );
}

class _GoalForm extends ConsumerStatefulWidget {
  const _GoalForm();

  @override
  ConsumerState<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<_GoalForm> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  DateTime? _deadline;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final target = double.tryParse(_target.text.replaceAll(',', '.'));
    if (_name.text.trim().isEmpty || target == null || target <= 0) {
      setState(() => _error = 'Укажите название и цель > 0');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(goalsRepositoryProvider).create(
          name: _name.text.trim(),
          targetAmount: target,
          deadline: _deadline,
        );
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
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Новая цель', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
                labelText: 'Название', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Целевая сумма', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(_deadline == null
                    ? 'Срок: не задан'
                    : 'Срок: ${_deadline!.toIso8601String().split('T').first}'),
              ),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 90)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _deadline = picked);
                },
                child: const Text('Выбрать'),
              ),
            ],
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
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Создать'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 8: Создать экран списка целей**

Create `lib/features/goals/presentation/pages/goals_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../providers/goals_providers.dart';
import '../widgets/goal_form_sheet.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(goalsProvider);
    final fmt = NumberFormat.decimalPattern();
    return Scaffold(
      appBar: AppBar(title: const Text('Цели')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showGoalForm(context);
          if (created == true) ref.invalidate(goalsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Новая цель'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(goalsProvider.future),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 80),
            Center(child: Text('Ошибка: $e')),
          ]),
          data: (goals) {
            if (goals.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Center(child: Text('Целей пока нет')),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: goals.length,
              itemBuilder: (_, i) {
                final g = goals[i];
                return Card(
                  child: ListTile(
                    title: Text(g.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: (g.percentage / 100).clamp(0, 1).toDouble(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${fmt.format(g.savedAmount)} / ${fmt.format(g.targetAmount)}'
                          ' · ${g.status}',
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('${AppRoutes.goals.path}/${g.id}'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 9: Создать экран цели с взносами**

Create `lib/features/goals/presentation/pages/goal_detail_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_result.dart';
import '../providers/goals_providers.dart';

class GoalDetailPage extends ConsumerWidget {
  const GoalDetailPage({required this.goalId, super.key});
  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(goalContributionsProvider(goalId));
    final fmt = NumberFormat.decimalPattern();
    return Scaffold(
      appBar: AppBar(title: const Text('Цель')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addContribution(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Пополнить'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Взносов пока нет'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final c = items[i];
              return ListTile(
                title: Text('+${fmt.format(c.amount)}'),
                subtitle: Text(
                  '${c.contributedOn.toIso8601String().split('T').first}'
                  '${c.note != null ? ' · ${c.note}' : ''}',
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addContribution(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сумма взноса'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Например, 5000'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(
                ctx, double.tryParse(controller.text.replaceAll(',', '.'))),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    final result = await ref.read(goalsRepositoryProvider).addContribution(
          goalId: goalId,
          amount: amount,
          contributedOn: DateTime.now(),
        );
    if (result is Ok) {
      ref.invalidate(goalContributionsProvider(goalId));
      ref.invalidate(goalsProvider);
    }
  }
}
```

- [ ] **Step 10: Подключить экраны целей в `app_router.dart`**

В `lib/app/router/app_router.dart`:

(а) добавить импорты:
```dart
import '../../features/goals/presentation/pages/goals_page.dart';
import '../../features/goals/presentation/pages/goal_detail_page.dart';
```

(б) добавить маршруты в список `routes:`:
```dart
      GoRoute(
        path: AppRoutes.goals.path,
        name: AppRoutes.goals.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const GoalsPage(),
        ),
        routes: [
          GoRoute(
            path: ':id',
            pageBuilder: (ctx, state) => fadeThroughPage(
              key: state.pageKey,
              child: GoalDetailPage(goalId: state.pathParameters['id']!),
            ),
          ),
        ],
      ),
```

- [ ] **Step 11: Проверить анализ**

Run: `cd frontend && flutter analyze lib/features/goals`
Expected: `No issues found!`

- [ ] **Step 12: Commit**

```bash
git add frontend/lib/features/goals test/features/goals frontend/lib/app/router/app_router.dart
git commit -m "feat(frontend): цели — data/провайдеры/экраны/взносы с тестом и маршрутами"
```

---

## Task 5: Статистика — data source, репозиторий, провайдеры

**Files:**
- Create: `lib/features/statistics/data/statistics_data_source.dart`
- Create: `lib/features/statistics/data/statistics_repository.dart`
- Create: `lib/features/statistics/presentation/providers/statistics_providers.dart`

- [ ] **Step 1: Создать data source**

Create `lib/features/statistics/data/statistics_data_source.dart`:
```dart
import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/envelope.dart';
import 'models/statistics_models.dart';

class StatisticsDataSource {
  StatisticsDataSource(this._dio);
  final Dio _dio;

  Future<SummaryModel> summary() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.statSummary);
    return SummaryModel.fromJson(unwrapObject(res.data));
  }

  Future<List<CategoryBreakdownModel>> byCategory(String type) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.statByCategory,
      queryParameters: {'type': type},
    );
    return unwrapList(res.data)
        .map((e) => CategoryBreakdownModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TrendPointModel>> trend() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.statTrend);
    return unwrapList(res.data)
        .map((e) => TrendPointModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
```

- [ ] **Step 2: Создать репозиторий**

Create `lib/features/statistics/data/statistics_repository.dart`:
```dart
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_result.dart';
import 'models/statistics_models.dart';
import 'statistics_data_source.dart';

class StatisticsRepository {
  StatisticsRepository(this._ds);
  final StatisticsDataSource _ds;

  Future<Result<SummaryModel>> summary() => _guard(_ds.summary);

  Future<Result<List<CategoryBreakdownModel>>> byCategory(String type) =>
      _guard(() => _ds.byCategory(type));

  Future<Result<List<TrendPointModel>>> trend() => _guard(_ds.trend);

  Future<Result<T>> _guard<T>(Future<T> Function() task) async {
    try {
      return Result.ok(await task());
    } catch (e) {
      return Result.err(mapDioError(e));
    }
  }
}
```

- [ ] **Step 3: Создать провайдеры**

Create `lib/features/statistics/presentation/providers/statistics_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/statistics_models.dart';
import '../../data/statistics_data_source.dart';
import '../../data/statistics_repository.dart';

final statisticsDataSourceProvider = Provider<StatisticsDataSource>((ref) {
  return StatisticsDataSource(ref.watch(dioProvider));
});

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository(ref.watch(statisticsDataSourceProvider));
});

final summaryProvider = FutureProvider.autoDispose<SummaryModel>((ref) async {
  final result = await ref.watch(statisticsRepositoryProvider).summary();
  return switch (result) {
    Ok<SummaryModel>(value: final v) => v,
    Err<SummaryModel>(failure: final f) => throw Exception(f.toString()),
  };
});

final expenseByCategoryProvider =
    FutureProvider.autoDispose<List<CategoryBreakdownModel>>((ref) async {
  final result =
      await ref.watch(statisticsRepositoryProvider).byCategory('EXPENSE');
  return switch (result) {
    Ok<List<CategoryBreakdownModel>>(value: final v) => v,
    Err<List<CategoryBreakdownModel>>(failure: final f) =>
      throw Exception(f.toString()),
  };
});

final trendProvider =
    FutureProvider.autoDispose<List<TrendPointModel>>((ref) async {
  final result = await ref.watch(statisticsRepositoryProvider).trend();
  return switch (result) {
    Ok<List<TrendPointModel>>(value: final v) => v,
    Err<List<TrendPointModel>>(failure: final f) => throw Exception(f.toString()),
  };
});
```

- [ ] **Step 4: Проверить анализ**

Run: `cd frontend && flutter analyze lib/features/statistics`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/statistics
git commit -m "feat(frontend): статистика — data source, репозиторий и провайдеры"
```

---

## Task 6: Дашборд на реальных данных

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/balance_card.dart`
- Modify: `lib/features/dashboard/presentation/widgets/spending_chart_card.dart`
- Modify: `lib/features/dashboard/presentation/pages/dashboard_page.dart`

- [ ] **Step 1: Параметризовать `BalanceCard` (income/expense)**

В `lib/features/dashboard/presentation/widgets/balance_card.dart`:

(а) добавить поля в конструктор — заменить блок конструктора и полей:
```dart
  const BalanceCard({
    required this.balance,
    required this.currency,
    required this.delta,
    required this.income,
    required this.expense,
    super.key,
  });

  final double balance;
  final String currency;
  final double income;
  final double expense;

  /// Percent change vs last month (e.g. 0.082 = +8.2%).
  final double delta;
```

(б) заменить жёстко зашитые суммы в `_MiniStat`:
```dart
                  _MiniStat(label: 'Income', value: '+${fmt.format(income)}'),
                  const SizedBox(width: AppSpacing.lg),
                  _MiniStat(label: 'Expense', value: '-${fmt.format(expense)}'),
```

- [ ] **Step 2: Переписать `SpendingChartCard` под входные данные**

Заменить ВЕСЬ файл `lib/features/dashboard/presentation/widgets/spending_chart_card.dart` на:
```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// График трат по месяцам. [monthly] — суммы расходов помесячно.
class SpendingChartCard extends StatelessWidget {
  const SpendingChartCard({
    required this.monthly,
    required this.totalThisMonth,
    super.key,
  });

  final List<double> monthly;
  final double totalThisMonth;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern();
    final values = monthly.isEmpty ? <double>[0, 0] : monthly;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spending', style: AppTypography.title),
          const SizedBox(height: 2),
          Text('${fmt.format(totalThisMonth)} ₸ this month',
              style: AppTypography.caption),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 160,
            child: LineChart(
              _chartData(values),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.03);
  }

  LineChartData _chartData(List<double> values) {
    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.graphite900,
          tooltipRoundedRadius: 10,
          getTooltipItems: (spots) => spots
              .map((s) => LineTooltipItem(
                    s.y.toStringAsFixed(0),
                    AppTypography.caption.copyWith(color: Colors.white),
                  ))
              .toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          barWidth: 3,
          color: AppColors.brand500,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.brand500.withValues(alpha: 0.28),
                AppColors.brand500.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Переписать `dashboard_page.dart` на провайдеры**

Заменить ВЕСЬ файл `lib/features/dashboard/presentation/pages/dashboard_page.dart` на:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/hex_color.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../goals/presentation/providers/goals_providers.dart';
import '../../../statistics/presentation/providers/statistics_providers.dart';
import '../../../transactions/presentation/providers/finance_providers.dart';
import '../models/dashboard_mock.dart';
import '../widgets/balance_card.dart';
import '../widgets/goal_progress_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_transactions.dart';
import '../widgets/section_header.dart';
import '../widgets/spending_chart_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 720;
              return CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: _TopBar()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.xxxl,
                    ),
                    sliver: SliverList.list(
                      children: _staggered(
                          _buildSections(context, ref, wide: wide)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context, WidgetRef ref,
      {required bool wide}) {
    final summary = ref.watch(summaryProvider);
    final trend = ref.watch(trendProvider);
    final txs = ref.watch(transactionsProvider);
    final goals = ref.watch(goalsProvider);

    final balanceCard = summary.when(
      loading: () => const BalanceCard(
          balance: 0, currency: '₸', delta: 0, income: 0, expense: 0),
      error: (_, __) => const BalanceCard(
          balance: 0, currency: '₸', delta: 0, income: 0, expense: 0),
      data: (s) => BalanceCard(
        balance: s.net,
        currency: '₸',
        delta: 0,
        income: s.income,
        expense: s.expense,
      ),
    );

    final spendingCard = trend.when(
      loading: () =>
          const SpendingChartCard(monthly: [], totalThisMonth: 0),
      error: (_, __) =>
          const SpendingChartCard(monthly: [], totalThisMonth: 0),
      data: (points) => SpendingChartCard(
        monthly: points.map((p) => p.expense).toList(),
        totalThisMonth: points.isEmpty ? 0 : points.last.expense,
      ),
    );

    final recent = txs.when(
      loading: () => const SizedBox(
          height: 80, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => _ErrorBox(message: 'Операции: $e'),
      data: (page) => RecentTransactions(
        items: page.items
            .take(5)
            .map((t) => TxItem(
                  title: t.categoryName ?? '—',
                  subtitle:
                      '${t.isIncome ? 'Доход' : 'Расход'} · ${t.occurredOn.toIso8601String().split('T').first}',
                  amount: t.amount,
                  icon: t.isIncome
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: hexToColor(t.categoryColor),
                  isIncome: t.isIncome,
                ))
            .toList(),
      ),
    );

    final goalsCard = goals.when(
      loading: () => const SizedBox(
          height: 80, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => _ErrorBox(message: 'Цели: $e'),
      data: (list) => list.isEmpty
          ? const _ErrorBox(message: 'Целей пока нет')
          : GoalProgressCard(
              goals: list
                  .take(3)
                  .map((g) => GoalItem(
                        title: g.name,
                        current: g.savedAmount,
                        target: g.targetAmount,
                        color: hexToColor(g.color),
                      ))
                  .toList(),
            ),
    );

    final left = <Widget>[
      balanceCard,
      const SizedBox(height: AppSpacing.lg),
      const QuickActions(),
      const SizedBox(height: AppSpacing.xl),
      spendingCard,
    ];
    final right = <Widget>[
      SectionHeader(
        title: 'Goals',
        action: 'Manage',
        onAction: () => context.push(AppRoutes.goals.path),
      ),
      const SizedBox(height: AppSpacing.md),
      goalsCard,
      const SizedBox(height: AppSpacing.xl),
      SectionHeader(
        title: 'Recent transactions',
        action: 'View all',
        onAction: () => context.push(AppRoutes.transactions.path),
      ),
      const SizedBox(height: AppSpacing.md),
      recent,
    ];
    if (!wide) return [...left, const SizedBox(height: AppSpacing.xl), ...right];
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(children: left)),
          const SizedBox(width: AppSpacing.xl),
          Expanded(child: Column(children: right)),
        ],
      ),
    ];
  }

  List<Widget> _staggered(List<Widget> items) {
    return [
      for (var i = 0; i < items.length; i++)
        items[i].animate(delay: (60 * i).ms).fadeIn(duration: 380.ms).slideY(
              begin: 0.04,
              end: 0,
              curve: Curves.easeOutCubic,
            ),
    ];
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(message, style: AppTypography.caption),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isAdmin = user?.roles.contains('ADMIN') ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.brand500, AppColors.brand400],
              ),
            ),
            child: Text(
              'AS',
              style: AppTypography.title.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good evening',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.graphite500,
                  ),
                ),
                Text(user?.fullName ?? 'Aibek', style: AppTypography.h2),
              ],
            ),
          ),
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: _IconBubble(
                icon: Icons.admin_panel_settings_rounded,
                onTap: () => context.push(AppRoutes.admin.path),
              ),
            ),
          _IconBubble(
            icon: Icons.notifications_none_rounded,
            badge: true,
            onTap: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text('No new notifications')),
                );
            },
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, this.badge = false, this.onTap});
  final IconData icon;
  final bool badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowSoft,
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.graphite700),
          ),
          if (badge)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

> Примечание: AI-инсайты и «Family activity» удалены из дашборда (вне объёма A+B). Виджеты `ai_insight_card.dart` и `family_activity_card.dart` остаются в проекте, но больше не используются на дашборде — это ожидаемо.

- [ ] **Step 4: Проверить анализ всего проекта**

Run: `cd frontend && flutter analyze`
Expected: `No issues found!` (допустимы info-подсказки линтера, но не warnings/errors).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/dashboard/presentation/widgets/balance_card.dart frontend/lib/features/dashboard/presentation/widgets/spending_chart_card.dart frontend/lib/features/dashboard/presentation/pages/dashboard_page.dart
git commit -m "feat(frontend): дашборд на реальных данных (баланс, график, операции, цели)"
```

---

## Task 7: Финальная проверка (тесты + ручной прогон)

- [ ] **Step 1: Прогнать все frontend-тесты**

Run: `cd frontend && flutter test`
Expected: все тесты passed (repository-тесты транзакций и целей + существующие, если есть).

- [ ] **Step 2: Запустить весь стек и проверить дашборд вручную**

```bash
# БД и бэк (из Планов 1–2)
docker start aifb-db 2>/dev/null || docker run -d --name aifb-db \
  -e POSTGRES_DB=aifb -e POSTGRES_USER=aifb -e POSTGRES_PASSWORD=aifb -p 5432:5432 postgres:16
( cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew bootRun & )
# фронт (порт 3000 разрешён в CORS бэка)
cd frontend && flutter run -d chrome --web-port 3000
```
Проверить вручную: регистрация/вход → дашборд без «белого экрана»; добавить операцию на `/transactions` → баланс и график на дашборде обновляются; создать цель и пополнить на `/goals` → прогресс растёт, при достижении цели статус `COMPLETED`.

- [ ] **Step 3: Commit (если были правки по итогам прогона)**

```bash
git add -A frontend
git commit -m "fix(frontend): правки по итогам ручного прогона дашборда"
```

---

## Self-review (выполнено при написании плана)

- **Покрытие спеки:** новые фичи `transactions`/`goals`/`statistics`, экраны списков и форм, замена mock в дашборде (`balance_card` ← summary, `spending_chart_card` ← trend, `recent_transactions` ← последние операции, `goal_progress_card` ← goals), маршруты в `routes.dart`/`app_router.dart`, тесты репозиториев на `mocktail` — секция спеки «Интеграция во фронт» и «Тестирование (frontend)» закрыты. Статистика встроена в дашборд (отдельного экрана нет — по решению из спеки).
- **Плейсхолдеры:** отсутствуют — каждый шаг содержит полный код файла или точечную правку с указанием места и команду проверки.
- **Согласованность типов:** имя пакета `aifb` (из `pubspec.yaml`) используется во всех `package:aifb/...` импортах тестов. `Result`/`Ok`/`Err` сопоставляются через switch-pattern ровно как в `api_result.dart`. Конструкторы `BalanceCard(... income, expense)` и `SpendingChartCard(monthly, totalThisMonth)` согласованы между виджетами и их вызовами в `dashboard_page.dart`. Провайдеры `summaryProvider`/`trendProvider`/`transactionsProvider`/`goalsProvider` объявлены до использования.
- **Совместимость с бэком:** `unwrapObject`/`unwrapList` соответствуют конверту `{data,...}`; поля моделей (`savedAmount`, `percentage`, `categoryName`, `hasNext`, `items`) совпадают с DTO Планов 1–2.
- **Намеренные изменения вне строгой замены mock:** с дашборда убраны секции AI-инсайтов и Family activity (вне объёма A+B); соответствующие виджеты остаются в репозитории неиспользуемыми. Это зафиксировано в Task 6.
