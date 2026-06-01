import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/core/network/dio_client.dart';
import 'package:aifb/features/groups/data/groups_data_source.dart';
import 'package:aifb/features/groups/data/groups_repository.dart';
import 'package:aifb/features/groups/data/models/group_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final groupsDataSourceProvider = Provider<GroupsDataSource>((ref) {
  return GroupsDataSource(ref.watch(dioProvider));
});

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return GroupsRepository(ref.watch(groupsDataSourceProvider));
});

final groupsProvider =
    FutureProvider.autoDispose.family<List<GroupModel>, Scope>((ref, scope) async {
  final result = await ref.watch(groupsRepositoryProvider).list(scope: scope);
  return switch (result) {
    Ok<List<GroupModel>>(value: final v) => v,
    Err<List<GroupModel>>(failure: final f) => throw Exception(f.toString()),
  };
});
