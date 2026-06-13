import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../data/dto/event_dtos.dart';
import '../providers/calendar_providers.dart';
import '../widgets/event_form.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  IconData _icon(String type) => switch (type) {
        'BIRTHDAY' => Icons.cake_rounded,
        'MEETING' => Icons.groups_rounded,
        'SCHOOL' => Icons.school_rounded,
        _ => Icons.event_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(monthEventsProvider);
    final events = async.valueOrNull ?? const <EventOccurrence>[];
    List<EventOccurrence> forDay(DateTime d) =>
        events.where((e) => _sameDate(e.date, d)).toList();
    final dayEvents = forDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(title: const Text('Календарь')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created =
              await showEventForm(context, ref, initialDate: _selectedDay);
          if (created ?? false) ref.invalidate(monthEventsProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TableCalendar<EventOccurrence>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => _sameDate(d, _selectedDay),
            eventLoader: forDay,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Месяц'},
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) {
              _focusedDay = focused;
              ref.read(focusedMonthProvider.notifier).state =
                  DateTime(focused.year, focused.month, 1);
            },
          ),
          const Divider(height: 1),
          if (async.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: dayEvents.isEmpty
                ? const Center(child: Text('Нет событий на этот день'))
                : ListView.builder(
                    itemCount: dayEvents.length,
                    itemBuilder: (ctx, i) {
                      final e = dayEvents[i];
                      return ListTile(
                        leading: Icon(_icon(e.type)),
                        title: Text(e.title),
                        subtitle: Text(e.allDay ? 'Весь день' : (e.time ?? '')),
                        trailing:
                            e.recurring ? const Icon(Icons.repeat, size: 18) : null,
                        onTap: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (dctx) => AlertDialog(
                              title: const Text('Удалить событие?'),
                              content: Text(e.recurring
                                  ? 'Будет удалена вся серия «${e.title}».'
                                  : 'Удалить «${e.title}»?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dctx, false),
                                  child: const Text('Отмена'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(dctx, true),
                                  child: const Text('Удалить'),
                                ),
                              ],
                            ),
                          );
                          if (ok ?? false) {
                            await ref.read(eventRepositoryProvider).deleteEvent(e.eventId);
                            ref.invalidate(monthEventsProvider);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
