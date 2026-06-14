import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../dto/poll.dart';

abstract class PollRemoteDataSource {
  Future<List<Poll>> list();
  Future<Poll> create(String question, List<String> options);
  Future<void> vote(String pollId, String optionId);
  Future<void> close(String pollId);
}

class PollRemoteDataSourceImpl implements PollRemoteDataSource {
  PollRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<Poll>> list() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.polls);
    final data = res.data?['data'];
    if (data is! List) {
      throw DioException(
        requestOptions: RequestOptions(),
        message: 'Malformed envelope',
      );
    }
    return data
        .map((e) => Poll.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Poll> create(String question, List<String> options) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.polls,
      data: {'question': question, 'options': options},
    );
    final data = res.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: RequestOptions(),
        message: 'Malformed envelope',
      );
    }
    return Poll.fromJson(data);
  }

  @override
  Future<void> vote(String pollId, String optionId) async {
    await _dio.post<void>(
      '${ApiEndpoints.polls}/$pollId/vote',
      data: {'optionId': optionId},
    );
  }

  @override
  Future<void> close(String pollId) async {
    await _dio.post<void>('${ApiEndpoints.polls}/$pollId/close');
  }
}
