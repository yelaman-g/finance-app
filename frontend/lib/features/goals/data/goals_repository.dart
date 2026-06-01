import 'package:aifb/core/errors/error_mapper.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/goals/data/goals_data_source.dart';
import 'package:aifb/features/goals/data/models/goal_model.dart';

class GoalsRepository {
  GoalsRepository(this._ds);
  final GoalsDataSource _ds;

  Future<Result<List<GoalModel>>> list() => _guard(_ds.list);

  Future<Result<GoalModel>> get(String id) => _guard(() => _ds.get(id));

  Future<Result<GoalModel>> create({
    required String name,
    required double targetAmount,
    DateTime? deadline,
    String? icon,
    String? color,
  }) =>
      _guard(() => _ds.create({
            'name': name,
            'targetAmount': targetAmount,
            if (deadline != null) 'deadline': _date(deadline),
            if (icon != null) 'icon': icon,
            if (color != null) 'color': color,
          },),);

  Future<Result<void>> delete(String id) => _guard(() => _ds.delete(id));

  Future<Result<List<ContributionModel>>> contributions(String goalId) =>
      _guard(() => _ds.contributions(goalId));

  Future<Result<ContributionModel>> addContribution({
    required String goalId,
    required double amount,
    required DateTime contributedOn,
    String? note,
  }) =>
      _guard(() => _ds.addContribution(goalId, {
            'amount': amount,
            'contributedOn': _date(contributedOn),
            if (note != null && note.isNotEmpty) 'note': note,
          },),);

  Future<Result<T>> _guard<T>(Future<T> Function() task) async {
    try {
      return Result.ok(await task());
    } catch (e) {
      return Result.err(mapDioError(e));
    }
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
