import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_api_client.dart';
import '../state/admin_db_state.dart';

final adminDbControllerProvider =
    StateNotifierProvider<AdminDbController, AdminDbState>((ref) {
  return AdminDbController(ref.watch(adminApiClientProvider));
});

class AdminDbController extends StateNotifier<AdminDbState> {
  final AdminApiClient _apiClient;

  AdminDbController(this._apiClient) : super(const AdminDbState()) {
    loadTables();
  }

  Future<void> loadTables() async {
    state = state.copyWith(isLoadingTables: true, tableError: null);
    try {
      final tables = await _apiClient.getTables();
      state = state.copyWith(isLoadingTables: false, tables: tables);
    } catch (e) {
      state = state.copyWith(
        isLoadingTables: false,
        tableError: e.toString(),
      );
    }
  }

  Future<void> executeQuery(String query) async {
    if (query.trim().isEmpty) return;

    state = state.copyWith(isExecutingQuery: true, currentQuery: query);
    try {
      final result = await _apiClient.executeQuery(query);
      state = state.copyWith(isExecutingQuery: false, queryResult: result);
    } catch (e) {
      state = state.copyWith(isExecutingQuery: false);
      // Let UI handle exception or store in state
    }
  }
}
