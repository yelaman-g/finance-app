import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/reactions/data/models/reaction_dto.dart';
import 'package:aifb/features/reactions/data/reaction_remote_data_source.dart';
import 'package:aifb/features/reactions/data/reaction_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements ReactionRemoteDataSource {}

void main() {
  late _MockDataSource ds;
  late ReactionRepository repo;

  setUp(() {
    ds = _MockDataSource();
    repo = ReactionRepository(ds);
  });

  group('react', () {
    test('forwards call to datasource and returns Ok', () async {
      when(() => ds.react('tx1', '😅')).thenAnswer((_) async {});

      final result = await repo.react('tx1', '😅');

      expect(result, isA<Ok<void>>());
      verify(() => ds.react('tx1', '😅')).called(1);
    });

    test('maps DioException to Err', () async {
      when(() => ds.react(any(), any())).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/reactions')),
      );

      final result = await repo.react('tx1', '😅');

      expect(result, isA<Err<void>>());
    });
  });

  group('removeReaction', () {
    test('forwards call to datasource and returns Ok', () async {
      when(() => ds.removeReaction('tx1')).thenAnswer((_) async {});

      final result = await repo.removeReaction('tx1');

      expect(result, isA<Ok<void>>());
      verify(() => ds.removeReaction('tx1')).called(1);
    });

    test('maps DioException to Err', () async {
      when(() => ds.removeReaction(any())).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/reactions')),
      );

      final result = await repo.removeReaction('tx1');

      expect(result, isA<Err<void>>());
    });
  });

  group('reactionsFor', () {
    test('returns Ok with mapped reaction map', () async {
      when(() => ds.reactionsFor(['tx1', 'tx2'])).thenAnswer(
        (_) async => {
          'tx1': [
            const ReactionDto(userId: 'u1', emoji: '👍'),
            const ReactionDto(userId: 'u2', emoji: '❤️'),
          ],
          'tx2': [
            const ReactionDto(userId: 'u1', emoji: '😅'),
          ],
        },
      );

      final result = await repo.reactionsFor(['tx1', 'tx2']);

      expect(result, isA<Ok<Map<String, List<ReactionDto>>>>());
      final map = (result as Ok<Map<String, List<ReactionDto>>>).value;
      expect(map['tx1']!.length, 2);
      expect(map['tx1']!.first.emoji, '👍');
      expect(map['tx2']!.single.userId, 'u1');
    });

    test('returns empty map when datasource returns empty', () async {
      when(() => ds.reactionsFor(any())).thenAnswer((_) async => {});

      final result = await repo.reactionsFor(['tx1']);

      expect(result, isA<Ok<Map<String, List<ReactionDto>>>>());
      expect((result as Ok<Map<String, List<ReactionDto>>>).value, isEmpty);
    });

    test('maps DioException to Err', () async {
      when(() => ds.reactionsFor(any())).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/reactions')),
      );

      final result = await repo.reactionsFor(['tx1']);

      expect(result, isA<Err<Map<String, List<ReactionDto>>>>());
    });
  });
}
