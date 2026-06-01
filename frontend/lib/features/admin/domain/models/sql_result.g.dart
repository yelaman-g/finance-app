// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sql_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SqlResultImpl _$$SqlResultImplFromJson(Map<String, dynamic> json) =>
    _$SqlResultImpl(
      columns:
          (json['columns'] as List<dynamic>?)?.map((e) => e as String).toList(),
      rows: (json['rows'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$$SqlResultImplToJson(_$SqlResultImpl instance) =>
    <String, dynamic>{
      'columns': instance.columns,
      'rows': instance.rows,
      'error': instance.error,
    };
