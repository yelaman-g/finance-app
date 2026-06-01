import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/categorization/data/categorization_data_source.dart';
import 'package:aifb/features/categorization/data/categorization_repository.dart';
import 'package:aifb/features/categorization/data/models/rule_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDs extends Mock implements CategorizationDataSource {}

void main() {
  late _MockDs ds;
  late CategorizationRepository repo;

  setUp(() {
    ds = _MockDs();
    repo = CategorizationRepository(ds);
  });

  test('list returns Ok with rules', () async {
    when(ds.list).thenAnswer((_) async => const [
          RuleModel(
            id: 'r1',
            keyword: 'magnum',
            categoryId: 'c1',
            categoryName: 'Еда',
          ),
        ]);
    final result = await repo.list();
    expect(result, isA<Ok<List<RuleModel>>>());
    expect((result as Ok<List<RuleModel>>).value.single.keyword, 'magnum');
  });

  test('list maps error to Err', () async {
    when(ds.list).thenThrow(
      DioException(
          requestOptions:
              RequestOptions(path: '/categorization/rules')),
    );
    final result = await repo.list();
    expect(result, isA<Err<List<RuleModel>>>());
  });
}
