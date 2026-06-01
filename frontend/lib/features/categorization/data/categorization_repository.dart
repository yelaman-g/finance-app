import 'package:aifb/core/errors/error_mapper.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/categorization/data/categorization_data_source.dart';
import 'package:aifb/features/categorization/data/models/rule_model.dart';

class CategorizationRepository {
  CategorizationRepository(this._ds);
  final CategorizationDataSource _ds;

  Future<Result<List<RuleModel>>> list() => _guard(_ds.list);

  Future<Result<RuleModel>> create({
    required String keyword,
    required String categoryId,
  }) =>
      _guard(
        () => _ds.create({'keyword': keyword, 'categoryId': categoryId}),
      );

  Future<Result<void>> delete(String id) => _guard(() => _ds.delete(id));

  Future<Result<String?>> suggest({
    required String note,
    required String type,
  }) =>
      _guard(() => _ds.suggest(note, type));

  Future<Result<T>> _guard<T>(Future<T> Function() task) async {
    try {
      return Result.ok(await task());
    } catch (e) {
      return Result.err(mapDioError(e));
    }
  }
}
