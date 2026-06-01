import 'package:aifb/core/errors/error_mapper.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/statistics/data/models/statistics_models.dart';
import 'package:aifb/features/statistics/data/statistics_data_source.dart';

class StatisticsRepository {
  StatisticsRepository(this._ds);
  final StatisticsDataSource _ds;

  Future<Result<SummaryModel>> summary() => _guard(_ds.summary);

  Future<Result<List<CategoryBreakdownModel>>> byCategory(String type) =>
      _guard(() => _ds.byCategory(type));

  Future<Result<List<TrendPointModel>>> trend() => _guard(_ds.trend);

  Future<Result<T>> _guard<T>(Future<T> Function() task) async {
    try {
      return Result.ok(await task());
    } catch (e) {
      return Result.err(mapDioError(e));
    }
  }
}
