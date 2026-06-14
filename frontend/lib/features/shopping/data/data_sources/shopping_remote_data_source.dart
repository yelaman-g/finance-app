import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../dto/shopping_item.dart';

abstract class ShoppingRemoteDataSource {
  Future<List<ShoppingItem>> list();
  Future<ShoppingItem> add(String title);
  Future<ShoppingItem> toggle(String id);
  Future<void> delete(String id);
}

class ShoppingRemoteDataSourceImpl implements ShoppingRemoteDataSource {
  ShoppingRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<ShoppingItem>> list() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.shopping);
    final data = res.data?['data'];
    if (data is! List) {
      throw DioException(
        requestOptions: RequestOptions(),
        message: 'Malformed envelope',
      );
    }
    return data
        .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ShoppingItem> add(String title) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.shopping,
      data: {'title': title},
    );
    final data = res.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: RequestOptions(),
        message: 'Malformed envelope',
      );
    }
    return ShoppingItem.fromJson(data);
  }

  @override
  Future<ShoppingItem> toggle(String id) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '${ApiEndpoints.shopping}/$id/toggle',
    );
    final data = res.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: RequestOptions(),
        message: 'Malformed envelope',
      );
    }
    return ShoppingItem.fromJson(data);
  }

  @override
  Future<void> delete(String id) async {
    await _dio.delete<void>('${ApiEndpoints.shopping}/$id');
  }
}
