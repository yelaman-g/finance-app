import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/ai_remote_data_source.dart';
import '../../data/repositories/ai_assistant_repository_impl.dart';
import '../../domain/repositories/ai_assistant_repository.dart';

final aiRemoteDataSourceProvider = Provider<AiRemoteDataSource>((ref) {
  return AiRemoteDataSourceImpl(ref.watch(dioProvider));
});

final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>((ref) {
  return AiAssistantRepositoryImpl(ref.watch(aiRemoteDataSourceProvider));
});
