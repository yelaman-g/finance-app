import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../dto/auth_dtos.dart';

/// Pure transport. Throws [DioException] — mapping happens in repository.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);
  final Dio _dio;

  Future<AuthSessionDto> login(LoginRequestDto body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: body.toJson(),
      options: Options(extra: {'skipAuth': true}),
    );
    return AuthSessionDto.fromJson(_unwrap(res.data));
  }

  Future<AuthSessionDto> register(RegisterRequestDto body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: body.toJson(),
      options: Options(extra: {'skipAuth': true}),
    );
    return AuthSessionDto.fromJson(_unwrap(res.data));
  }

  Future<UserDto> me() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
    return UserDto.fromJson(_unwrap(res.data));
  }

  Future<void> logout() async {
    await _dio.post<void>(ApiEndpoints.logout);
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post<void>(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
      options: Options(extra: {'skipAuth': true}),
    );
  }

  Future<void> resetPassword({
    required String code,
    required String newPassword,
  }) async {
    await _dio.post<void>(
      ApiEndpoints.resetPassword,
      data: {'code': code, 'newPassword': newPassword},
      options: Options(extra: {'skipAuth': true}),
    );
  }

  Future<void> verifyEmail(String code) async {
    await _dio.post<void>(
      ApiEndpoints.verifyEmail,
      data: {'code': code},
    );
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    if (body == null) {
      throw DioException(
        requestOptions: RequestOptions(),
        message: 'Empty response',
      );
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: RequestOptions(),
        message: 'Malformed envelope',
      );
    }
    return data;
  }
}
