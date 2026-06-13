import '../../domain/repositories/event_repository.dart';
import '../data_sources/event_remote_data_source.dart';
import '../dto/event_dtos.dart';

class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(this._remote);
  final EventRemoteDataSource _remote;

  @override
  Future<List<EventOccurrence>> getEvents(DateTime from, DateTime to, String scope) =>
      _remote.getEvents(from, to, scope);

  @override
  Future<EventDetail> createEvent(Map<String, dynamic> body) => _remote.createEvent(body);

  @override
  Future<void> deleteEvent(String id) => _remote.deleteEvent(id);
}
