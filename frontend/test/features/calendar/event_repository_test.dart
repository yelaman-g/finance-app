import 'package:aifb/features/calendar/data/dto/event_dtos.dart';
import 'package:aifb/features/calendar/data/data_sources/event_remote_data_source.dart';
import 'package:aifb/features/calendar/data/repositories/event_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements EventRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late EventRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = EventRepositoryImpl(remote);
  });

  test('getEvents returns occurrences', () async {
    final occ = EventOccurrence(
      eventId: 'e1', title: 'Тренировка', date: DateTime(2026, 6, 8),
      allDay: true, type: 'OTHER', recurring: true,
    );
    when(() => remote.getEvents(any(), any())).thenAnswer((_) async => [occ]);
    final res = await repo.getEvents(DateTime(2026, 6, 1), DateTime(2026, 6, 30));
    expect(res, hasLength(1));
    expect(res.first.title, 'Тренировка');
  });

  test('createEvent forwards body and returns detail', () async {
    when(() => remote.createEvent(any()))
        .thenAnswer((_) async => const EventDetail(id: 'e1', title: 'ДР'));
    final res = await repo.createEvent({'title': 'ДР'});
    expect(res.id, 'e1');
    verify(() => remote.createEvent(any())).called(1);
  });
}
