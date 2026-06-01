import 'package:aifb/core/network/api_endpoints.dart';
import 'package:aifb/core/network/envelope.dart';
import 'package:aifb/features/household/data/models/household_model.dart';
import 'package:dio/dio.dart';

class HouseholdDataSource {
  HouseholdDataSource(this._dio);
  final Dio _dio;

  Future<HouseholdModel> me() async {
    final res =
        await _dio.get<Map<String, dynamic>>('${ApiEndpoints.households}/me');
    return HouseholdModel.fromJson(unwrapObject(res.data));
  }

  Future<HouseholdModel> create(String name) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.households,
      data: {'name': name},
    );
    return HouseholdModel.fromJson(unwrapObject(res.data));
  }

  Future<HouseholdModel> join(String inviteCode) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '${ApiEndpoints.households}/join',
      data: {'inviteCode': inviteCode},
    );
    return HouseholdModel.fromJson(unwrapObject(res.data));
  }

  Future<HouseholdModel> changeRole(String userId, String role) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '${ApiEndpoints.households}/members/$userId/role',
      data: {'role': role},
    );
    return HouseholdModel.fromJson(unwrapObject(res.data));
  }

  Future<void> removeMember(String userId) async {
    await _dio.delete<void>('${ApiEndpoints.households}/members/$userId');
  }

  Future<void> leave() async {
    await _dio.post<void>('${ApiEndpoints.households}/leave');
  }

  Future<void> disband() async {
    await _dio.delete<void>(ApiEndpoints.households);
  }

  Future<HouseholdModel> rotateCode() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '${ApiEndpoints.households}/rotate-code',
    );
    return HouseholdModel.fromJson(unwrapObject(res.data));
  }
}
