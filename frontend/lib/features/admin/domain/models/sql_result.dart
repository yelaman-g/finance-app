import 'package:freezed_annotation/freezed_annotation.dart';

part 'sql_result.freezed.dart';
part 'sql_result.g.dart';

@freezed
class SqlResult with _$SqlResult {
  const factory SqlResult({
    List<String>? columns,
    List<Map<String, dynamic>>? rows,
    String? error,
  }) = _SqlResult;

  factory SqlResult.fromJson(Map<String, dynamic> json) =>
      _$SqlResultFromJson(json);
}
