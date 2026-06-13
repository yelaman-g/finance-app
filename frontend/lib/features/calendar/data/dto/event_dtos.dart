class EventOccurrence {
  const EventOccurrence({
    required this.eventId,
    required this.title,
    this.description,
    required this.date,
    this.time,
    required this.allDay,
    required this.type,
    required this.recurring,
  });
  final String eventId;
  final String title;
  final String? description;
  final DateTime date;
  final String? time;
  final bool allDay;
  final String type;
  final bool recurring;

  factory EventOccurrence.fromJson(Map<String, dynamic> j) => EventOccurrence(
        eventId: j['eventId'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        date: DateTime.parse(j['date'] as String),
        time: j['time'] as String?,
        allDay: j['allDay'] as bool? ?? true,
        type: j['type'] as String? ?? 'OTHER',
        recurring: j['recurring'] as bool? ?? false,
      );
}

class EventDetail {
  const EventDetail({required this.id, required this.title});
  final String id;
  final String title;
  factory EventDetail.fromJson(Map<String, dynamic> j) =>
      EventDetail(id: j['id'] as String, title: j['title'] as String);
}
