import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../dto/moment.dart';

abstract class FeedRemoteDataSource {
  Future<List<Moment>> list();
  Future<Moment> post(String text);
  Future<void> delete(String id);
  Future<void> like(String id);
  Future<void> unlike(String id);
}

class FeedRemoteDataSourceImpl implements FeedRemoteDataSource {
  FeedRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<Moment>> list() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.feed);
    final data = res.data?['data'];
    if (data is! List) {
      throw DioException(
        requestOptions: RequestOptions(),
        message: 'Malformed envelope',
      );
    }
    return data
        .map((e) => Moment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Moment> post(String text) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.feed,
      data: {'text': text},
    );
    final data = res.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: RequestOptions(),
        message: 'Malformed envelope',
      );
    }
    return Moment.fromJson(data);
  }

  @override
  Future<void> delete(String id) async {
    await _dio.delete<void>('${ApiEndpoints.feed}/$id');
  }

  @override
  Future<void> like(String id) async {
    await _dio.post<void>('${ApiEndpoints.feed}/$id/like');
  }

  @override
  Future<void> unlike(String id) async {
    await _dio.delete<void>('${ApiEndpoints.feed}/$id/like');
  }
}
