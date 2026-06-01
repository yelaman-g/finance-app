import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/core/network/dio_client.dart';
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

final summaryProvider = FutureProvider.autoDispose<SummaryModel>((ref) async {
  final result = await ref.watch(statisticsRepositoryProvider).summary();
  return switch (result) {
    Ok<SummaryModel>(value: final v) => v,
    Err<SummaryModel>(failure: final f) => throw Exception(f.toString()),
  };
});

final expenseByCategoryProvider =
    FutureProvider.autoDispose<List<CategoryBreakdownModel>>((ref) async {
  final result =
      await ref.watch(statisticsRepositoryProvider).byCategory('EXPENSE');
  return switch (result) {
    Ok<List<CategoryBreakdownModel>>(value: final v) => v,
    Err<List<CategoryBreakdownModel>>(failure: final f) =>
      throw Exception(f.toString()),
  };
});

final trendProvider =
    FutureProvider.autoDispose<List<TrendPointModel>>((ref) async {
  final result = await ref.watch(statisticsRepositoryProvider).trend();
  return switch (result) {
    Ok<List<TrendPointModel>>(value: final v) => v,
    Err<List<TrendPointModel>>(failure: final f) =>
      throw Exception(f.toString()),
  };
});
