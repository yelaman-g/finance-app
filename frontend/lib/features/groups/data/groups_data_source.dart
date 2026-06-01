import 'package:aifb/core/network/api_endpoints.dart';
import 'package:aifb/core/network/envelope.dart';
import 'package:aifb/features/groups/data/models/group_model.dart';
import 'package:dio/dio.dart';

class GroupsDataSource {
  GroupsDataSource(this._dio);
  final Dio _dio;

  Future<List<GroupModel>> list(String? type, {String scope = 'PERSONAL'}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.groups,
      queryParameters: {if (type != null) 'type': type, 'scope': scope},
    );
    return unwrapList(res.data)
        .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GroupModel> create(Map<String, dynamic> body) async {
    final res =
        await _dio.post<Map<String, dynamic>>(ApiEndpoints.groups, data: body);
    return GroupModel.fromJson(unwrapObject(res.data));
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('${ApiEndpoints.groups}/$id');
  }
}
