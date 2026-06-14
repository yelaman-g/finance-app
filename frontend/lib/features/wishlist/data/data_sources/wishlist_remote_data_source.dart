import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../dto/wishlist_item.dart';

abstract class WishlistRemoteDataSource {
  Future<List<WishlistItem>> list();
  Future<WishlistItem> add(String title, String? note);
  Future<void> delete(String id);
  Future<void> reserve(String id);
  Future<void> unreserve(String id);
}

class WishlistRemoteDataSourceImpl implements WishlistRemoteDataSource {
  WishlistRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<WishlistItem>> list() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.wishlist);
    final data = res.data?['data'];
    if (data is! List) {
      throw DioException(
        requestOptions: RequestOptions(),
        message: 'Malformed envelope',
      );
    }
    return data
        .map((e) => WishlistItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WishlistItem> add(String title, String? note) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.wishlist,
      data: {
        'title': title,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    final data = res.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: RequestOptions(),
        message: 'Malformed envelope',
      );
    }
    return WishlistItem.fromJson(data);
  }

  @override
  Future<void> delete(String id) async {
    await _dio.delete<void>('${ApiEndpoints.wishlist}/$id');
  }

  @override
  Future<void> reserve(String id) async {
    await _dio.post<void>('${ApiEndpoints.wishlist}/$id/reserve');
  }

  @override
  Future<void> unreserve(String id) async {
    await _dio.delete<void>('${ApiEndpoints.wishlist}/$id/reserve');
  }
}
