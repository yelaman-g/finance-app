import 'package:aifb/core/network/api_endpoints.dart';
import 'package:aifb/core/network/envelope.dart';
import 'package:aifb/features/statistics/data/models/statistics_models.dart';
import 'package:dio/dio.dart';

class StatisticsDataSource {
  StatisticsDataSource(this._dio);
  final Dio _dio;

  Future<SummaryModel> summary() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.statSummary);
    return SummaryModel.fromJson(unwrapObject(res.data));
  }

  Future<List<CategoryBreakdownModel>> byCategory(String type) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.statByCategory,
      queryParameters: {'type': type},
    );
    return unwrapList(res.data)
        .map((e) => CategoryBreakdownModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TrendPointModel>> trend() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.statTrend);
    return unwrapList(res.data)
        .map((e) => TrendPointModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
