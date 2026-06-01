import 'package:dio/dio.dart';

/// Разворачивает объект из конверта бэка `{ "data": {...} }`.
Map<String, dynamic> unwrapObject(Map<String, dynamic>? body) {
  final data = body?['data'];
  if (data is Map<String, dynamic>) return data;
  throw DioException(
    requestOptions: RequestOptions(),
    message: 'Malformed envelope (expected object)',
  );
}

/// Разворачивает массив из конверта бэка `{ "data": [...] }`.
List<dynamic> unwrapList(Map<String, dynamic>? body) {
  final data = body?['data'];
  if (data is List) return data;
  throw DioException(
    requestOptions: RequestOptions(),
    message: 'Malformed envelope (expected array)',
  );
}
