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
        ],);

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
