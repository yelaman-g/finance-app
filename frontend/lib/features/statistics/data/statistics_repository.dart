import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/core/errors/error_mapper.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/statistics/data/models/member_breakdown_model.dart';
import 'package:aifb/features/statistics/data/models/statistics_models.dart';
import 'package:aifb/features/statistics/data/statistics_data_source.dart';

class StatisticsRepository {
  StatisticsRepository(this._ds);
  final StatisticsDataSource _ds;

  Future<Result<SummaryModel>> summary({Scope scope = Scope.personal}) =>
      _guard(() => _ds.summary(scope: scope.query));

  Future<Result<List<CategoryBreakdownModel>>> byCategory(
    String type, {
    Scope scope = Scope.personal,
  }) =>
      _guard(() => _ds.byCategory(type, scope: scope.query));

  Future<Result<List<TrendPointModel>>> trend({Scope scope = Scope.personal}) =>
      _guard(() => _ds.trend(scope: scope.query));

  Future<Result<List<MemberBreakdownModel>>> byMember() =>
      _guard(_ds.byMember);

  Future<Result<T>> _guard<T>(Future<T> Function() task) async {
    try {
      return Result.ok(await task());
    } catch (e) {
      return Result.err(mapDioError(e));
    }
  }
}
