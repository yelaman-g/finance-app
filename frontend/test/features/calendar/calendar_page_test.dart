import 'package:aifb/app/theme/app_theme.dart';
import 'package:aifb/features/calendar/data/dto/event_dtos.dart';
import 'package:aifb/features/calendar/domain/repositories/event_repository.dart';
import 'package:aifb/features/calendar/presentation/pages/calendar_page.dart';
import 'package:aifb/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeRepo implements EventRepository {
  @override
  Future<List<EventOccurrence>> getEvents(DateTime from, DateTime to, String scope) async => const [];
  @override
  Future<EventDetail> createEvent(Map<String, dynamic> body) async =>
      const EventDetail(id: 'e1', title: 't');
  @override
  Future<void> deleteEvent(String id) async {}
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru_RU', null);
  });

  testWidgets('CalendarPage renders calendar and empty-day hint', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [eventRepositoryProvider.overrideWithValue(_FakeRepo())],
      child: MaterialApp(theme: AppTheme.light, home: const CalendarPage()),
    ));
    await tester.pump();
    expect(find.text('Календарь'), findsOneWidget);
    expect(find.text('Нет событий на этот день'), findsOneWidget);
  });
}
