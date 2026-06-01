import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/models/sql_result.dart';

final adminApiClientProvider = Provider<AdminApiClient>((ref) {
  return AdminApiClient(ref.watch(dioProvider));
});

class AdminApiClient {
  final Dio _dio;

  AdminApiClient(this._dio);

  Future<List<String>> getTables() async {
    final response = await _dio.get(ApiEndpoints.adminDbTables);
    if (response.statusCode == 200) {
      final data = response.data['data'] as List;
      return data.cast<String>();
    }
    throw Exception('Failed to load tables');
  }

  Future<SqlResult> executeQuery(String query) async {
    final response = await _dio.post(
      ApiEndpoints.adminDbQuery,
      data: {'query': query},
    );
    if (response.statusCode == 200) {
      return SqlResult.fromJson(response.data['data']);
    }
    throw Exception('Failed to execute query');
  }
}
