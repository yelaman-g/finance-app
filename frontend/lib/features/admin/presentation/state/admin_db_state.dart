import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/models/sql_result.dart';

part 'admin_db_state.freezed.dart';

@freezed
class AdminDbState with _$AdminDbState {
  const factory AdminDbState({
    @Default(false) bool isLoadingTables,
    @Default([]) List<String> tables,
    String? tableError,
    @Default(false) bool isExecutingQuery,
    SqlResult? queryResult,
    String? currentQuery,
  }) = _AdminDbState;
}
