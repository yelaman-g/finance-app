import 'package:aifb/core/network/api_endpoints.dart';
import 'package:aifb/core/network/envelope.dart';
import 'package:aifb/features/transactions/data/models/category_model.dart';
import 'package:aifb/features/transactions/data/models/page_result.dart';
import 'package:aifb/features/transactions/data/models/transaction_model.dart';
import 'package:dio/dio.dart';

/// Чистый транспорт к /categories и /transactions. Бросает [DioException].
class FinanceDataSource {
  FinanceDataSource(this._dio);
  final Dio _dio;

  Future<List<CategoryModel>> categories(
    String? type, {
    String scope = 'PERSONAL',
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.categories,
      queryParameters: {
        if (type != null) 'type': type,
        'scope': scope,
      },
    );
    return unwrapList(res.data)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PageResult<TransactionModel>> transactions({
    String? type,
    String? categoryId,
    DateTime? from,
    DateTime? to,
    int page = 0,
    int size = 20,
    String scope = 'PERSONAL',
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.transactions,
      queryParameters: {
        if (type != null) 'type': type,
        if (categoryId != null) 'categoryId': categoryId,
        if (from != null) 'from': _date(from),
        if (to != null) 'to': _date(to),
        'page': page,
        'size': size,
        'scope': scope,
      },
    );
    return PageResult.fromJson(
      unwrapObject(res.data),
      TransactionModel.fromJson,
    );
  }

  Future<TransactionModel> create(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.transactions,
      data: body,
    );
    return TransactionModel.fromJson(unwrapObject(res.data));
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('${ApiEndpoints.transactions}/$id');
  }

  Future<CategoryModel> createCategory(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.categories,
      data: body,
    );
    return CategoryModel.fromJson(unwrapObject(res.data));
  }

  Future<CategoryModel> updateCategory(String id, Map<String, dynamic> body) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '${ApiEndpoints.categories}/$id',
      data: body,
    );
    return CategoryModel.fromJson(unwrapObject(res.data));
  }

  Future<void> deleteCategory(String id) async {
    await _dio.delete<void>('${ApiEndpoints.categories}/$id');
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
