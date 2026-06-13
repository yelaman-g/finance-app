import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';

abstract class PushRemoteDataSource {
  Future<void> registerToken(String token, String platform);
  Future<void> deleteToken(String token);
}

class PushRemoteDataSourceImpl implements PushRemoteDataSource {
  PushRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<void> registerToken(String token, String platform) async {
    await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.pushTokens,
      data: {'token': token, 'platform': platform},
    );
  }

  @override
  Future<void> deleteToken(String token) async {
    await _dio.delete<Map<String, dynamic>>('${ApiEndpoints.pushTokens}/$token');
  }
}
