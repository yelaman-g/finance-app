import 'package:aifb/core/network/api_endpoints.dart';
import 'package:aifb/core/network/envelope.dart';
import 'package:aifb/features/goals/data/models/goal_model.dart';
import 'package:dio/dio.dart';

class GoalsDataSource {
  GoalsDataSource(this._dio);
  final Dio _dio;

  Future<List<GoalModel>> list({String scope = 'PERSONAL'}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.goals,
      queryParameters: {'scope': scope},
    );
    return unwrapList(res.data)
        .map((e) => GoalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GoalModel> get(String id) async {
    final res =
        await _dio.get<Map<String, dynamic>>('${ApiEndpoints.goals}/$id');
    return GoalModel.fromJson(unwrapObject(res.data));
  }

  Future<GoalModel> create(Map<String, dynamic> body) async {
    final res =
        await _dio.post<Map<String, dynamic>>(ApiEndpoints.goals, data: body);
    return GoalModel.fromJson(unwrapObject(res.data));
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('${ApiEndpoints.goals}/$id');
  }

  Future<List<ContributionModel>> contributions(String goalId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '${ApiEndpoints.goals}/$goalId/contributions',
    );
    return unwrapList(res.data)
        .map((e) => ContributionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ContributionModel> addContribution(
    String goalId,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '${ApiEndpoints.goals}/$goalId/contributions',
      data: body,
    );
    return ContributionModel.fromJson(unwrapObject(res.data));
  }
}
