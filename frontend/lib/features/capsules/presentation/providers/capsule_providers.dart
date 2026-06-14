import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/capsule_remote_data_source.dart';
import '../../data/dto/capsule.dart';
import '../../data/repositories/capsule_repository_impl.dart';
import '../../domain/repositories/capsule_repository.dart';

final capsuleRepositoryProvider = Provider<CapsuleRepository>((ref) {
  return CapsuleRepositoryImpl(
    CapsuleRemoteDataSourceImpl(ref.watch(dioProvider)),
  );
});

final capsulesProvider = FutureProvider.autoDispose<List<Capsule>>((ref) {
  return ref.watch(capsuleRepositoryProvider).list();
});
