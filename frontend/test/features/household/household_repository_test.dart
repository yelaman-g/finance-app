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
    when(() => ds.create('Семья')).thenAnswer(
      (_) async => const HouseholdModel(
        id: 'h1',
        name: 'Семья',
        myRole: 'OWNER',
        members: [],
        inviteCode: 'ABC',
      ),
    );
    final result = await repo.create('Семья');
    expect(result, isA<Ok<HouseholdModel>>());
    expect((result as Ok<HouseholdModel>).value.isOwner, isTrue);
  });

  test('me maps notFound error to Err', () async {
    when(ds.me).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/households/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/households/me'),
          statusCode: 404,
          data: const {
            'error': {'code': 'NOT_FOUND', 'message': 'нет семьи'},
          },
        ),
      ),
    );
    final result = await repo.me();
    expect(result, isA<Err<HouseholdModel>>());
  });
}
