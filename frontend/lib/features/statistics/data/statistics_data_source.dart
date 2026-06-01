import 'package:aifb/core/network/api_endpoints.dart';
import 'package:aifb/core/network/envelope.dart';
import 'package:aifb/features/statistics/data/models/member_breakdown_model.dart';
import 'package:aifb/features/statistics/data/models/statistics_models.dart';
import 'package:dio/dio.dart';

class StatisticsDataSource {
  StatisticsDataSource(this._dio);
  final Dio _dio;

  Future<SummaryModel> summary({String scope = 'PERSONAL'}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.statSummary,
      queryParameters: {'scope': scope},
    );
    return SummaryModel.fromJson(unwrapObject(res.data));
  }

  Future<List<CategoryBreakdownModel>> byCategory(
    String type, {
    String scope = 'PERSONAL',
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.statByCategory,
      queryParameters: {'type': type, 'scope': scope},
    );
    return unwrapList(res.data)
        .map((e) => CategoryBreakdownModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TrendPointModel>> trend({String scope = 'PERSONAL'}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.statTrend,
      queryParameters: {'scope': scope},
    );
    return unwrapList(res.data)
        .map((e) => TrendPointModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MemberBreakdownModel>> byMember() async {
    final res =
        await _dio.get<Map<String, dynamic>>(ApiEndpoints.statByMember);
    return unwrapList(res.data)
        .map(
          (e) => MemberBreakdownModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }
}
