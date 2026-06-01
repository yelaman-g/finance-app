import 'package:aifb/core/network/api_endpoints.dart';
import 'package:aifb/core/network/envelope.dart';
import 'package:aifb/features/categorization/data/models/rule_model.dart';
import 'package:dio/dio.dart';

class CategorizationDataSource {
  CategorizationDataSource(this._dio);
  final Dio _dio;

  Future<List<RuleModel>> list() async {
    final res =
        await _dio.get<Map<String, dynamic>>(ApiEndpoints.categorizationRules);
    return unwrapList(res.data)
        .map((e) => RuleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RuleModel> create(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.categorizationRules,
      data: body,
    );
    return RuleModel.fromJson(unwrapObject(res.data));
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('${ApiEndpoints.categorizationRules}/$id');
  }

  Future<String?> suggest(String note, String type) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.categorizationSuggest,
      data: {'note': note, 'type': type},
    );
    final data = res.data?['data'];
    if (data is Map<String, dynamic>) {
      return data['categoryId'] as String?;
    }
    return null;
  }
}
