import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../dto/event_dtos.dart';

abstract class EventRemoteDataSource {
  Future<List<EventOccurrence>> getEvents(DateTime from, DateTime to);
  Future<EventDetail> createEvent(Map<String, dynamic> body);
  Future<void> deleteEvent(String id);
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  EventRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  String _d(DateTime d) => d.toIso8601String().split('T').first;

  @override
  Future<List<EventOccurrence>> getEvents(DateTime from, DateTime to) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.events,
      queryParameters: {'from': _d(from), 'to': _d(to)},
    );
    final data = res.data?['data'];
    if (data is! List) {
      throw DioException(requestOptions: RequestOptions(), message: 'Malformed envelope');
    }
    return data.map((e) => EventOccurrence.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<EventDetail> createEvent(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(ApiEndpoints.events, data: body);
    final data = res.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw DioException(requestOptions: RequestOptions(), message: 'Malformed envelope');
    }
    return EventDetail.fromJson(data);
  }

  @override
  Future<void> deleteEvent(String id) async {
    await _dio.delete<void>('${ApiEndpoints.events}/$id');
  }
}
