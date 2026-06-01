import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/groups/data/groups_data_source.dart';
import 'package:aifb/features/groups/data/groups_repository.dart';
import 'package:aifb/features/groups/data/models/group_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDs extends Mock implements GroupsDataSource {}

void main() {
  late _MockDs ds;
  late GroupsRepository repo;

  setUp(() {
    ds = _MockDs();
    repo = GroupsRepository(ds);
  });

  test('list returns Ok with groups', () async {
    when(() => ds.list('EXPENSE', scope: 'PERSONAL')).thenAnswer((_) async => const [
          GroupModel(id: 'g1', name: 'Коммунальные', type: 'EXPENSE', shared: false),
        ]);
    final result = await repo.list(type: 'EXPENSE');
    expect(result, isA<Ok<List<GroupModel>>>());
    expect((result as Ok<List<GroupModel>>).value.single.name, 'Коммунальные');
  });

  test('list maps error to Err', () async {
    when(() => ds.list(any(), scope: any(named: 'scope'))).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/groups')),
    );
    final result = await repo.list(type: 'EXPENSE');
    expect(result, isA<Err<List<GroupModel>>>());
  });
}
