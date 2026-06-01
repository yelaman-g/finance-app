import 'package:aifb/core/network/api_endpoints.dart';
import 'package:aifb/core/network/envelope.dart';
import 'package:aifb/features/budgets/data/models/budget_model.dart';
import 'package:dio/dio.dart';

class BudgetsDataSource {
  BudgetsDataSource(this._dio);
  final Dio _dio;

  Future<List<BudgetModel>> list({String scope = 'PERSONAL'}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.budgets,
      queryParameters: {'scope': scope},
    );
    return unwrapList(res.data)
        .map((e) => BudgetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BudgetModel> create(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.budgets,
      data: body,
    );
    return BudgetModel.fromJson(unwrapObject(res.data));
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('${ApiEndpoints.budgets}/$id');
  }
}
