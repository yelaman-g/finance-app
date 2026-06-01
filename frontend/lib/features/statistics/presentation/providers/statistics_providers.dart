import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/core/network/dio_client.dart';
import 'package:aifb/features/statistics/data/models/member_breakdown_model.dart';
import 'package:aifb/features/statistics/data/models/statistics_models.dart';
import 'package:aifb/features/statistics/data/statistics_data_source.dart';
import 'package:aifb/features/statistics/data/statistics_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final statisticsDataSourceProvider = Provider<StatisticsDataSource>((ref) {
  return StatisticsDataSource(ref.watch(dioProvider));
});

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository(ref.watch(statisticsDataSourceProvider));
});

final summaryProvider =
    FutureProvider.autoDispose.family<SummaryModel, Scope>((ref, scope) async {
  final result =
      await ref.watch(statisticsRepositoryProvider).summary(scope: scope);
  return switch (result) {
    Ok<SummaryModel>(value: final v) => v,
    Err<SummaryModel>(failure: final f) => throw Exception(f.toString()),
  };
});

final expenseByCategoryProvider =
    FutureProvider.autoDispose
        .family<List<CategoryBreakdownModel>, Scope>((ref, scope) async {
  final result = await ref
      .watch(statisticsRepositoryProvider)
      .byCategory('EXPENSE', scope: scope);
  return switch (result) {
    Ok<List<CategoryBreakdownModel>>(value: final v) => v,
    Err<List<CategoryBreakdownModel>>(failure: final f) =>
      throw Exception(f.toString()),
  };
});

final trendProvider =
    FutureProvider.autoDispose
        .family<List<TrendPointModel>, Scope>((ref, scope) async {
  final result =
      await ref.watch(statisticsRepositoryProvider).trend(scope: scope);
  return switch (result) {
    Ok<List<TrendPointModel>>(value: final v) => v,
    Err<List<TrendPointModel>>(failure: final f) =>
      throw Exception(f.toString()),
  };
});

final memberBreakdownProvider =
    FutureProvider.autoDispose<List<MemberBreakdownModel>>((ref) async {
  final result = await ref.watch(statisticsRepositoryProvider).byMember();
  return switch (result) {
    Ok<List<MemberBreakdownModel>>(value: final v) => v,
    Err<List<MemberBreakdownModel>>(failure: final f) =>
      throw Exception(f.toString()),
  };
});
