import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/core/network/dio_client.dart';
import 'package:aifb/features/transactions/data/finance_data_source.dart';
import 'package:aifb/features/transactions/data/finance_repository.dart';
import 'package:aifb/features/transactions/data/models/category_model.dart';
import 'package:aifb/features/transactions/data/models/page_result.dart';
import 'package:aifb/features/transactions/data/models/transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final financeDataSourceProvider = Provider<FinanceDataSource>((ref) {
  return FinanceDataSource(ref.watch(dioProvider));
});

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(ref.watch(financeDataSourceProvider));
});

final categoriesProvider =
    FutureProvider.family<List<CategoryModel>, String?>((ref, type) async {
  final result =
      await ref.watch(financeRepositoryProvider).categories(type: type);
  return switch (result) {
    Ok<List<CategoryModel>>(value: final v) => v,
    Err<List<CategoryModel>>(failure: final f) => throw Exception(f.toString()),
  };
});

final transactionsProvider =
    FutureProvider.autoDispose<PageResult<TransactionModel>>((ref) async {
  final result =
      await ref.watch(financeRepositoryProvider).transactions(size: 50);
  return switch (result) {
    Ok<PageResult<TransactionModel>>(value: final v) => v,
    Err<PageResult<TransactionModel>>(failure: final f) =>
      throw Exception(f.toString()),
  };
});
