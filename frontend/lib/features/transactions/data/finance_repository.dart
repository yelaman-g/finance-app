import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/core/errors/error_mapper.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/transactions/data/finance_data_source.dart';
import 'package:aifb/features/transactions/data/models/category_model.dart';
import 'package:aifb/features/transactions/data/models/page_result.dart';
import 'package:aifb/features/transactions/data/models/transaction_model.dart';

class FinanceRepository {
  FinanceRepository(this._ds);
  final FinanceDataSource _ds;

  Future<Result<List<CategoryModel>>> categories({
    String? type,
    Scope scope = Scope.personal,
  }) =>
      _guard(() => _ds.categories(type, scope: scope.query));

  Future<Result<PageResult<TransactionModel>>> transactions({
    String? type,
    String? categoryId,
    DateTime? from,
    DateTime? to,
    int page = 0,
    int size = 20,
    Scope scope = Scope.personal,
  }) =>
      _guard(
        () => _ds.transactions(
          type: type,
          categoryId: categoryId,
          from: from,
          to: to,
          page: page,
          size: size,
          scope: scope.query,
        ),
      );

  Future<Result<TransactionModel>> create({
    required String categoryId,
    required String type,
    required double amount,
    required DateTime occurredOn,
    String? note,
    bool shared = false,
  }) =>
      _guard(
        () => _ds.create({
          'categoryId': categoryId,
          'type': type,
          'amount': amount,
          'occurredOn': _date(occurredOn),
          if (note != null && note.isNotEmpty) 'note': note,
          'shared': shared,
        }),
      );

  Future<Result<void>> delete(String id) => _guard(() => _ds.delete(id));

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
