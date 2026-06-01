import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/core/network/dio_client.dart';
import 'package:aifb/features/household/data/household_data_source.dart';
import 'package:aifb/features/household/data/household_repository.dart';
import 'package:aifb/features/household/data/models/household_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final householdDataSourceProvider = Provider<HouseholdDataSource>((ref) {
  return HouseholdDataSource(ref.watch(dioProvider));
});

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return HouseholdRepository(ref.watch(householdDataSourceProvider));
});

final myHouseholdProvider =
    FutureProvider.autoDispose<HouseholdModel?>((ref) async {
  final result = await ref.watch(householdRepositoryProvider).me();
  return switch (result) {
    Ok<HouseholdModel>(value: final v) => v,
    Err<HouseholdModel>() => null,
  };
});
