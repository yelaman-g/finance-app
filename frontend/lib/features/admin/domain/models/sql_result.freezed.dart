// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sql_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SqlResult _$SqlResultFromJson(Map<String, dynamic> json) {
  return _SqlResult.fromJson(json);
}

/// @nodoc
mixin _$SqlResult {
  List<String>? get columns => throw _privateConstructorUsedError;
  List<Map<String, dynamic>>? get rows => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Serializes this SqlResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SqlResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SqlResultCopyWith<SqlResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SqlResultCopyWith<$Res> {
  factory $SqlResultCopyWith(SqlResult value, $Res Function(SqlResult) then) =
      _$SqlResultCopyWithImpl<$Res, SqlResult>;
  @useResult
  $Res call(
      {List<String>? columns, List<Map<String, dynamic>>? rows, String? error});
}

/// @nodoc
class _$SqlResultCopyWithImpl<$Res, $Val extends SqlResult>
    implements $SqlResultCopyWith<$Res> {
  _$SqlResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SqlResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? columns = freezed,
    Object? rows = freezed,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      columns: freezed == columns
          ? _value.columns
          : columns // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      rows: freezed == rows
          ? _value.rows
          : rows // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SqlResultImplCopyWith<$Res>
    implements $SqlResultCopyWith<$Res> {
  factory _$$SqlResultImplCopyWith(
          _$SqlResultImpl value, $Res Function(_$SqlResultImpl) then) =
      __$$SqlResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<String>? columns, List<Map<String, dynamic>>? rows, String? error});
}

/// @nodoc
class __$$SqlResultImplCopyWithImpl<$Res>
    extends _$SqlResultCopyWithImpl<$Res, _$SqlResultImpl>
    implements _$$SqlResultImplCopyWith<$Res> {
  __$$SqlResultImplCopyWithImpl(
      _$SqlResultImpl _value, $Res Function(_$SqlResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of SqlResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? columns = freezed,
    Object? rows = freezed,
    Object? error = freezed,
  }) {
    return _then(_$SqlResultImpl(
      columns: freezed == columns
          ? _value._columns
          : columns // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      rows: freezed == rows
          ? _value._rows
          : rows // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SqlResultImpl implements _SqlResult {
  const _$SqlResultImpl(
      {final List<String>? columns,
      final List<Map<String, dynamic>>? rows,
      this.error})
      : _columns = columns,
        _rows = rows;

  factory _$SqlResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$SqlResultImplFromJson(json);

  final List<String>? _columns;
  @override
  List<String>? get columns {
    final value = _columns;
    if (value == null) return null;
    if (_columns is EqualUnmodifiableListView) return _columns;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<Map<String, dynamic>>? _rows;
  @override
  List<Map<String, dynamic>>? get rows {
    final value = _rows;
    if (value == null) return null;
    if (_rows is EqualUnmodifiableListView) return _rows;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? error;

  @override
  String toString() {
    return 'SqlResult(columns: $columns, rows: $rows, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SqlResultImpl &&
            const DeepCollectionEquality().equals(other._columns, _columns) &&
            const DeepCollectionEquality().equals(other._rows, _rows) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_columns),
      const DeepCollectionEquality().hash(_rows),
      error);

  /// Create a copy of SqlResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SqlResultImplCopyWith<_$SqlResultImpl> get copyWith =>
      __$$SqlResultImplCopyWithImpl<_$SqlResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SqlResultImplToJson(
      this,
    );
  }
}

abstract class _SqlResult implements SqlResult {
  const factory _SqlResult(
      {final List<String>? columns,
      final List<Map<String, dynamic>>? rows,
      final String? error}) = _$SqlResultImpl;

  factory _SqlResult.fromJson(Map<String, dynamic> json) =
      _$SqlResultImpl.fromJson;

  @override
  List<String>? get columns;
  @override
  List<Map<String, dynamic>>? get rows;
  @override
  String? get error;

  /// Create a copy of SqlResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SqlResultImplCopyWith<_$SqlResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
