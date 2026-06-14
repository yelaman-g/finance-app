import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../dto/capsule.dart';

abstract class CapsuleRemoteDataSource {
  Future<List<Capsule>> list();
  Future<Capsule> create(String title, String message, DateTime openDate);
  Future<void> delete(String id);
}

class CapsuleRemoteDataSourceImpl implements CapsuleRemoteDataSource {
  CapsuleRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<Capsule>> list() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.capsules);
    final data = res.data?['data'];
    if (data is! List) {
      throw DioException(
        requestOptions: RequestOptions(),
        message: 'Malformed envelope',
      );
    }
    return data
        .map((e) => Capsule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Capsule> create(
    String title,
    String message,
    DateTime openDate,
  ) async {
    final dateStr =
        '${openDate.year.toString().padLeft(4, '0')}-'
        '${openDate.month.toString().padLeft(2, '0')}-'
        '${openDate.day.toString().padLeft(2, '0')}';
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.capsules,
      data: {'title': title, 'message': message, 'openDate': dateStr},
    );
    final data = res.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: RequestOptions(),
        message: 'Malformed envelope',
      );
    }
    return Capsule.fromJson(data);
  }

  @override
  Future<void> delete(String id) async {
    await _dio.delete<void>('${ApiEndpoints.capsules}/$id');
  }
}
