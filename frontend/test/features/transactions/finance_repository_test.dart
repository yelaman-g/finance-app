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
    when(() => ds.categories('EXPENSE', scope: 'PERSONAL')).thenAnswer(
      (_) async => const [
        CategoryModel(id: '1', name: 'Еда', type: 'EXPENSE', system: true),
      ],
    );

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
