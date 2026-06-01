import 'package:aifb/core/errors/error_mapper.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/household/data/household_data_source.dart';
import 'package:aifb/features/household/data/models/household_model.dart';

class HouseholdRepository {
  HouseholdRepository(this._ds);
  final HouseholdDataSource _ds;

  Future<Result<HouseholdModel>> me() => _guard(_ds.me);
  Future<Result<HouseholdModel>> create(String name) =>
      _guard(() => _ds.create(name));
  Future<Result<HouseholdModel>> join(String code) =>
      _guard(() => _ds.join(code));
  Future<Result<HouseholdModel>> changeRole(String userId, String role) =>
      _guard(() => _ds.changeRole(userId, role));
  Future<Result<void>> removeMember(String userId) =>
      _guard(() => _ds.removeMember(userId));
  Future<Result<void>> leave() => _guard(_ds.leave);
  Future<Result<void>> disband() => _guard(_ds.disband);
  Future<Result<HouseholdModel>> rotateCode() => _guard(_ds.rotateCode);

  Future<Result<T>> _guard<T>(Future<T> Function() task) async {
    try {
      return Result.ok(await task());
    } catch (e) {
      return Result.err(mapDioError(e));
    }
  }
}
