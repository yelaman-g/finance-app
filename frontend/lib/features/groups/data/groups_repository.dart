import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/core/errors/error_mapper.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/groups/data/groups_data_source.dart';
import 'package:aifb/features/groups/data/models/group_model.dart';

class GroupsRepository {
  GroupsRepository(this._ds);
  final GroupsDataSource _ds;

  Future<Result<List<GroupModel>>> list({String? type, Scope scope = Scope.personal}) =>
      _guard(() => _ds.list(type, scope: scope.query));

  Future<Result<GroupModel>> create({
    required String name,
    required String type,
    bool shared = false,
    String? icon,
    String? color,
  }) =>
      _guard(() => _ds.create({
            'name': name,
            'type': type,
            'shared': shared,
            if (icon != null) 'icon': icon,
            if (color != null) 'color': color,
          }));

  Future<Result<void>> delete(String id) => _guard(() => _ds.delete(id));

  Future<Result<T>> _guard<T>(Future<T> Function() task) async {
    try {
      return Result.ok(await task());
    } catch (e) {
      return Result.err(mapDioError(e));
    }
  }
}
