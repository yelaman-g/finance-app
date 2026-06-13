import '../../data/dto/event_dtos.dart';

abstract class EventRepository {
  Future<List<EventOccurrence>> getEvents(DateTime from, DateTime to);
  Future<EventDetail> createEvent(Map<String, dynamic> body);
  Future<void> deleteEvent(String id);
}
