import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/budgets/data/budgets_data_source.dart';
import 'package:aifb/features/budgets/data/budgets_repository.dart';
import 'package:aifb/features/budgets/data/models/budget_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDs extends Mock implements BudgetsDataSource {}

void main() {
  late _MockDs ds;
  late BudgetsRepository repo;

  setUp(() {
    ds = _MockDs();
    repo = BudgetsRepository(ds);
  });

  test('list returns Ok with budgets', () async {
    when(() => ds.list(scope: any(named: 'scope'))).thenAnswer(
      (_) async => const [
        BudgetModel(
          id: 'b1',
          targetType: 'CATEGORY',
          targetId: 'c1',
          targetName: 'Еда',
          amount: 1000,
          spent: 850,
          percentage: 85,
          status: 'WARNING',
          shared: false,
        ),
      ],
    );
    final result = await repo.list();
    expect(result, isA<Ok<List<BudgetModel>>>());
    expect((result as Ok<List<BudgetModel>>).value.single.status, 'WARNING');
  });

  test('list maps error to Err', () async {
    when(() => ds.list(scope: any(named: 'scope'))).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/budgets')),
    );
    final result = await repo.list();
    expect(result, isA<Err<List<BudgetModel>>>());
  });

  test('update returns Ok with budget', () async {
    when(() => ds.update('b1', {'amount': 500.0})).thenAnswer((_) async =>
        const BudgetModel(
          id: 'b1', targetType: 'CATEGORY', targetId: 'c1', targetName: 'Еда',
          amount: 500, spent: 0, percentage: 0, status: 'OK', shared: false,
        ),);
    final result = await repo.update(id: 'b1', amount: 500);
    expect(result, isA<Ok<BudgetModel>>());
    expect((result as Ok<BudgetModel>).value.amount, 500);
  });
}
