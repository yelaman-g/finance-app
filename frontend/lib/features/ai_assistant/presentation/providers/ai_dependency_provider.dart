import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_sources/ai_remote_data_source.dart';
import '../../data/repositories/ai_assistant_repository_impl.dart';
import '../../domain/repositories/ai_assistant_repository.dart';

final aiDioProvider = Provider<Dio>((ref) {
  return Dio();
});

final aiRemoteDataSourceProvider = Provider<AiRemoteDataSource>((ref) {
  final dio = ref.watch(aiDioProvider);
  return AiRemoteDataSourceImpl(dio);
});

final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>((ref) {
  final dataSource = ref.watch(aiRemoteDataSourceProvider);
  return AiAssistantRepositoryImpl(dataSource);
});
