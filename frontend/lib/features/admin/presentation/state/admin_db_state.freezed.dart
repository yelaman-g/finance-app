// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_db_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AdminDbState {
  bool get isLoadingTables => throw _privateConstructorUsedError;
  List<String> get tables => throw _privateConstructorUsedError;
  String? get tableError => throw _privateConstructorUsedError;
  bool get isExecutingQuery => throw _privateConstructorUsedError;
  SqlResult? get queryResult => throw _privateConstructorUsedError;
  String? get currentQuery => throw _privateConstructorUsedError;

  /// Create a copy of AdminDbState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdminDbStateCopyWith<AdminDbState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdminDbStateCopyWith<$Res> {
  factory $AdminDbStateCopyWith(
          AdminDbState value, $Res Function(AdminDbState) then) =
      _$AdminDbStateCopyWithImpl<$Res, AdminDbState>;
  @useResult
  $Res call(
      {bool isLoadingTables,
      List<String> tables,
      String? tableError,
      bool isExecutingQuery,
      SqlResult? queryResult,
      String? currentQuery});

  $SqlResultCopyWith<$Res>? get queryResult;
}

/// @nodoc
class _$AdminDbStateCopyWithImpl<$Res, $Val extends AdminDbState>
    implements $AdminDbStateCopyWith<$Res> {
  _$AdminDbStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdminDbState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoadingTables = null,
    Object? tables = null,
    Object? tableError = freezed,
    Object? isExecutingQuery = null,
    Object? queryResult = freezed,
    Object? currentQuery = freezed,
  }) {
    return _then(_value.copyWith(
      isLoadingTables: null == isLoadingTables
          ? _value.isLoadingTables
          : isLoadingTables // ignore: cast_nullable_to_non_nullable
              as bool,
      tables: null == tables
          ? _value.tables
          : tables // ignore: cast_nullable_to_non_nullable
              as List<String>,
      tableError: freezed == tableError
          ? _value.tableError
          : tableError // ignore: cast_nullable_to_non_nullable
              as String?,
      isExecutingQuery: null == isExecutingQuery
          ? _value.isExecutingQuery
          : isExecutingQuery // ignore: cast_nullable_to_non_nullable
              as bool,
      queryResult: freezed == queryResult
          ? _value.queryResult
          : queryResult // ignore: cast_nullable_to_non_nullable
              as SqlResult?,
      currentQuery: freezed == currentQuery
          ? _value.currentQuery
          : currentQuery // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of AdminDbState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SqlResultCopyWith<$Res>? get queryResult {
    if (_value.queryResult == null) {
      return null;
    }

    return $SqlResultCopyWith<$Res>(_value.queryResult!, (value) {
      return _then(_value.copyWith(queryResult: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AdminDbStateImplCopyWith<$Res>
    implements $AdminDbStateCopyWith<$Res> {
  factory _$$AdminDbStateImplCopyWith(
          _$AdminDbStateImpl value, $Res Function(_$AdminDbStateImpl) then) =
      __$$AdminDbStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoadingTables,
      List<String> tables,
      String? tableError,
      bool isExecutingQuery,
      SqlResult? queryResult,
      String? currentQuery});

  @override
  $SqlResultCopyWith<$Res>? get queryResult;
}

/// @nodoc
class __$$AdminDbStateImplCopyWithImpl<$Res>
    extends _$AdminDbStateCopyWithImpl<$Res, _$AdminDbStateImpl>
    implements _$$AdminDbStateImplCopyWith<$Res> {
  __$$AdminDbStateImplCopyWithImpl(
      _$AdminDbStateImpl _value, $Res Function(_$AdminDbStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of AdminDbState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoadingTables = null,
    Object? tables = null,
    Object? tableError = freezed,
    Object? isExecutingQuery = null,
    Object? queryResult = freezed,
    Object? currentQuery = freezed,
  }) {
    return _then(_$AdminDbStateImpl(
      isLoadingTables: null == isLoadingTables
          ? _value.isLoadingTables
          : isLoadingTables // ignore: cast_nullable_to_non_nullable
              as bool,
      tables: null == tables
          ? _value._tables
          : tables // ignore: cast_nullable_to_non_nullable
              as List<String>,
      tableError: freezed == tableError
          ? _value.tableError
          : tableError // ignore: cast_nullable_to_non_nullable
              as String?,
      isExecutingQuery: null == isExecutingQuery
          ? _value.isExecutingQuery
          : isExecutingQuery // ignore: cast_nullable_to_non_nullable
              as bool,
      queryResult: freezed == queryResult
          ? _value.queryResult
          : queryResult // ignore: cast_nullable_to_non_nullable
              as SqlResult?,
      currentQuery: freezed == currentQuery
          ? _value.currentQuery
          : currentQuery // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$AdminDbStateImpl implements _AdminDbState {
  const _$AdminDbStateImpl(
      {this.isLoadingTables = false,
      final List<String> tables = const [],
      this.tableError,
      this.isExecutingQuery = false,
      this.queryResult,
      this.currentQuery})
      : _tables = tables;

  @override
  @JsonKey()
  final bool isLoadingTables;
  final List<String> _tables;
  @override
  @JsonKey()
  List<String> get tables {
    if (_tables is EqualUnmodifiableListView) return _tables;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tables);
  }

  @override
  final String? tableError;
  @override
  @JsonKey()
  final bool isExecutingQuery;
  @override
  final SqlResult? queryResult;
  @override
  final String? currentQuery;

  @override
  String toString() {
    return 'AdminDbState(isLoadingTables: $isLoadingTables, tables: $tables, tableError: $tableError, isExecutingQuery: $isExecutingQuery, queryResult: $queryResult, currentQuery: $currentQuery)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminDbStateImpl &&
            (identical(other.isLoadingTables, isLoadingTables) ||
                other.isLoadingTables == isLoadingTables) &&
            const DeepCollectionEquality().equals(other._tables, _tables) &&
            (identical(other.tableError, tableError) ||
                other.tableError == tableError) &&
            (identical(other.isExecutingQuery, isExecutingQuery) ||
                other.isExecutingQuery == isExecutingQuery) &&
            (identical(other.queryResult, queryResult) ||
                other.queryResult == queryResult) &&
            (identical(other.currentQuery, currentQuery) ||
                other.currentQuery == currentQuery));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isLoadingTables,
      const DeepCollectionEquality().hash(_tables),
      tableError,
      isExecutingQuery,
      queryResult,
      currentQuery);

  /// Create a copy of AdminDbState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminDbStateImplCopyWith<_$AdminDbStateImpl> get copyWith =>
      __$$AdminDbStateImplCopyWithImpl<_$AdminDbStateImpl>(this, _$identity);
}

abstract class _AdminDbState implements AdminDbState {
  const factory _AdminDbState(
      {final bool isLoadingTables,
      final List<String> tables,
      final String? tableError,
      final bool isExecutingQuery,
      final SqlResult? queryResult,
      final String? currentQuery}) = _$AdminDbStateImpl;

  @override
  bool get isLoadingTables;
  @override
  List<String> get tables;
  @override
  String? get tableError;
  @override
  bool get isExecutingQuery;
  @override
  SqlResult? get queryResult;
  @override
  String? get currentQuery;

  /// Create a copy of AdminDbState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdminDbStateImplCopyWith<_$AdminDbStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
