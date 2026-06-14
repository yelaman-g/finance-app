import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/core/errors/error_mapper.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/budgets/data/budgets_data_source.dart';
import 'package:aifb/features/budgets/data/models/budget_model.dart';

class BudgetsRepository {
  BudgetsRepository(this._ds);
  final BudgetsDataSource _ds;

  Future<Result<List<BudgetModel>>> list({Scope scope = Scope.personal}) =>
      _guard(() => _ds.list(scope: scope.query));

  Future<Result<BudgetModel>> create({
    required String targetType,
    required double amount,
    String? categoryId,
    String? groupId,
    bool shared = false,
    int notifyThresholdPercent = 80,
  }) =>
      _guard(() => _ds.create({
            'targetType': targetType,
            'amount': amount,
            'shared': shared,
            'notifyThresholdPercent': notifyThresholdPercent,
            if (categoryId != null) 'categoryId': categoryId,
            if (groupId != null) 'groupId': groupId,
          }),);

  Future<Result<void>> delete(String id) => _guard(() => _ds.delete(id));

  Future<Result<BudgetModel>> update({
    required String id,
    required double amount,
  }) =>
      _guard(() => _ds.update(id, {'amount': amount}));

  Future<Result<T>> _guard<T>(Future<T> Function() task) async {
    try {
      return Result.ok(await task());
    } catch (e) {
      return Result.err(mapDioError(e));
    }
  }
}
