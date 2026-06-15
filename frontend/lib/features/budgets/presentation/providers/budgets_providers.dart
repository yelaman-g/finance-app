import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/core/errors/failure_message.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/core/network/dio_client.dart';
import 'package:aifb/features/budgets/data/budgets_data_source.dart';
import 'package:aifb/features/budgets/data/budgets_repository.dart';
import 'package:aifb/features/budgets/data/models/budget_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final budgetsDataSourceProvider = Provider<BudgetsDataSource>((ref) {
  return BudgetsDataSource(ref.watch(dioProvider));
});

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return BudgetsRepository(ref.watch(budgetsDataSourceProvider));
});

final budgetsProvider =
    FutureProvider.autoDispose.family<List<BudgetModel>, Scope>(
        (ref, scope) async {
  final result =
      await ref.watch(budgetsRepositoryProvider).list(scope: scope);
  return switch (result) {
    Ok<List<BudgetModel>>(value: final v) => v,
    Err<List<BudgetModel>>(failure: final f) => throw Exception(f.userMessage),
  };
});
