import 'package:aifb/core/errors/failure_message.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/core/network/dio_client.dart';
import 'package:aifb/features/categorization/data/categorization_data_source.dart';
import 'package:aifb/features/categorization/data/categorization_repository.dart';
import 'package:aifb/features/categorization/data/models/rule_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categorizationDataSourceProvider = Provider<CategorizationDataSource>((ref) {
  return CategorizationDataSource(ref.watch(dioProvider));
});

final categorizationRepositoryProvider = Provider<CategorizationRepository>((ref) {
  return CategorizationRepository(ref.watch(categorizationDataSourceProvider));
});

final rulesProvider = FutureProvider.autoDispose<List<RuleModel>>((ref) async {
  final result = await ref.watch(categorizationRepositoryProvider).list();
  return switch (result) {
    Ok<List<RuleModel>>(value: final v) => v,
    Err<List<RuleModel>>(failure: final f) => throw Exception(f.userMessage),
  };
});
