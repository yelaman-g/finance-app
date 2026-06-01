import 'package:dio/dio.dart';

import 'failure.dart';

/// Maps Dio errors and backend error envelope to a domain [Failure].
/// Backend envelope shape:
/// { "data": null, "error": { "code": "...", "message": "...", "fields": {} } }
Failure mapDioError(Object error) {
  if (error is! DioException) {
    return Failure.unknown(message: error.toString());
  }
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return const Failure.timeout();
    case DioExceptionType.connectionError:
      return Failure.network(message: error.message);
    case DioExceptionType.badCertificate:
      return const Failure.network(message: 'Bad certificate');
    case DioExceptionType.cancel:
      return const Failure.unknown(message: 'Request cancelled');
    case DioExceptionType.unknown:
      return Failure.unknown(message: error.message);
    case DioExceptionType.badResponse:
      return _mapResponse(error.response);
  }
}

Failure _mapResponse(Response<dynamic>? response) {
  if (response == null) return const Failure.unknown();
  final status = response.statusCode ?? 0;
  final body = response.data;
  String? message;
  Map<String, String>? fields;
  if (body is Map && body['error'] is Map) {
    final err = body['error'] as Map;
    message = err['message'] as String?;
    final f = err['fields'];
    if (f is Map) {
      fields = f.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
  }
  switch (status) {
    case 400:
    case 422:
      return Failure.validation(
        message: message ?? 'Invalid request',
        fields: fields,
      );
    case 401:
      return Failure.unauthorized(message: message);
    case 403:
      return Failure.forbidden(message: message);
    case 404:
      return Failure.notFound(message: message);
    case 409:
      return Failure.conflict(message: message);
  }
  if (status >= 500) return Failure.server(message: message);
  return Failure.unknown(message: message);
}
