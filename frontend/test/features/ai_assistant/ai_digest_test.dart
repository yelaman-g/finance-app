import 'package:aifb/features/ai_assistant/data/data_sources/ai_remote_data_source.dart';
import 'package:aifb/features/ai_assistant/data/dto/ai_dtos.dart';
import 'package:aifb/features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements AiRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late AiAssistantRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = AiAssistantRepositoryImpl(remote);
  });

  test('digest() parses full response including upcoming events', () async {
    final digest = AiDigest(
      tipOfDay: 'Откладывайте 10% дохода',
      narrative: 'На этой неделе расходы выросли на 5%',
      highlights: ['Крупная покупка: телефон', 'Экономия на кафе'],
      upcomingEvents: [
        DigestEvent(title: 'День рождения', date: DateTime(2026, 7, 15)),
      ],
    );
    when(() => remote.digest()).thenAnswer((_) async => digest);

    final result = await repo.digest();

    expect(result.tipOfDay, 'Откладывайте 10% дохода');
    expect(result.narrative, 'На этой неделе расходы выросли на 5%');
    expect(result.highlights, hasLength(2));
    expect(result.upcomingEvents.first.title, 'День рождения');
    expect(result.upcomingEvents.first.date, DateTime(2026, 7, 15));
    verify(() => remote.digest()).called(1);
  });

  test('AiDigest.fromJson parses envelope data correctly', () {
    final json = {
      'tipOfDay': 'Совет',
      'narrative': 'Повествование',
      'highlights': ['Пункт 1', 'Пункт 2'],
      'upcomingEvents': [
        {'title': 'Событие', 'date': '2026-08-01'},
      ],
    };

    final result = AiDigest.fromJson(json);

    expect(result.tipOfDay, 'Совет');
    expect(result.narrative, 'Повествование');
    expect(result.highlights, ['Пункт 1', 'Пункт 2']);
    expect(result.upcomingEvents, hasLength(1));
    expect(result.upcomingEvents.first.title, 'Событие');
    expect(result.upcomingEvents.first.date, DateTime(2026, 8, 1));
  });

  test('DigestEvent.fromJson parses date string', () {
    final event = DigestEvent.fromJson({'title': 'Свадьба', 'date': '2026-09-20'});
    expect(event.title, 'Свадьба');
    expect(event.date.year, 2026);
    expect(event.date.month, 9);
    expect(event.date.day, 20);
  });

  test('AiDigest.fromJson handles empty lists gracefully', () {
    final json = {
      'tipOfDay': '',
      'narrative': '',
      'highlights': <dynamic>[],
      'upcomingEvents': <dynamic>[],
    };
    final result = AiDigest.fromJson(json);
    expect(result.highlights, isEmpty);
    expect(result.upcomingEvents, isEmpty);
  });
}
