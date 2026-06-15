import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/core/errors/failure_message.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/core/network/dio_client.dart';
import 'package:aifb/features/goals/data/goals_data_source.dart';
import 'package:aifb/features/goals/data/goals_repository.dart';
import 'package:aifb/features/goals/data/models/goal_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final goalsDataSourceProvider = Provider<GoalsDataSource>((ref) {
  return GoalsDataSource(ref.watch(dioProvider));
});

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepository(ref.watch(goalsDataSourceProvider));
});

final goalsProvider =
    FutureProvider.autoDispose.family<List<GoalModel>, Scope>((ref, scope) async {
  final result = await ref.watch(goalsRepositoryProvider).list(scope: scope);
  return switch (result) {
    Ok<List<GoalModel>>(value: final v) => v,
    Err<List<GoalModel>>(failure: final f) => throw Exception(f.userMessage),
  };
});

final goalContributionsProvider =
    FutureProvider.autoDispose.family<List<ContributionModel>, String>(
        (ref, goalId) async {
  final result = await ref.watch(goalsRepositoryProvider).contributions(goalId);
  return switch (result) {
    Ok<List<ContributionModel>>(value: final v) => v,
    Err<List<ContributionModel>>(failure: final f) =>
      throw Exception(f.userMessage),
  };
});
