// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Failure {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? message) network,
    required TResult Function() timeout,
    required TResult Function(String? message) unauthorized,
    required TResult Function(String? message) forbidden,
    required TResult Function(String? message) notFound,
    required TResult Function(String? message) conflict,
    required TResult Function(String message, Map<String, String>? fields)
        validation,
    required TResult Function(String? message) server,
    required TResult Function(String? message) unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? message)? network,
    TResult? Function()? timeout,
    TResult? Function(String? message)? unauthorized,
    TResult? Function(String? message)? forbidden,
    TResult? Function(String? message)? notFound,
    TResult? Function(String? message)? conflict,
    TResult? Function(String message, Map<String, String>? fields)? validation,
    TResult? Function(String? message)? server,
    TResult? Function(String? message)? unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? message)? network,
    TResult Function()? timeout,
    TResult Function(String? message)? unauthorized,
    TResult Function(String? message)? forbidden,
    TResult Function(String? message)? notFound,
    TResult Function(String? message)? conflict,
    TResult Function(String message, Map<String, String>? fields)? validation,
    TResult Function(String? message)? server,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkFailure value) network,
    required TResult Function(TimeoutFailure value) timeout,
    required TResult Function(UnauthorizedFailure value) unauthorized,
    required TResult Function(ForbiddenFailure value) forbidden,
    required TResult Function(NotFoundFailure value) notFound,
    required TResult Function(ConflictFailure value) conflict,
    required TResult Function(ValidationFailure value) validation,
    required TResult Function(ServerFailure value) server,
    required TResult Function(UnknownFailure value) unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkFailure value)? network,
    TResult? Function(TimeoutFailure value)? timeout,
    TResult? Function(UnauthorizedFailure value)? unauthorized,
    TResult? Function(ForbiddenFailure value)? forbidden,
    TResult? Function(NotFoundFailure value)? notFound,
    TResult? Function(ConflictFailure value)? conflict,
    TResult? Function(ValidationFailure value)? validation,
    TResult? Function(ServerFailure value)? server,
    TResult? Function(UnknownFailure value)? unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkFailure value)? network,
    TResult Function(TimeoutFailure value)? timeout,
    TResult Function(UnauthorizedFailure value)? unauthorized,
    TResult Function(ForbiddenFailure value)? forbidden,
    TResult Function(NotFoundFailure value)? notFound,
    TResult Function(ConflictFailure value)? conflict,
    TResult Function(ValidationFailure value)? validation,
    TResult Function(ServerFailure value)? server,
    TResult Function(UnknownFailure value)? unknown,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FailureCopyWith<$Res> {
  factory $FailureCopyWith(Failure value, $Res Function(Failure) then) =
      _$FailureCopyWithImpl<$Res, Failure>;
}

/// @nodoc
class _$FailureCopyWithImpl<$Res, $Val extends Failure>
    implements $FailureCopyWith<$Res> {
  _$FailureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$NetworkFailureImplCopyWith<$Res> {
  factory _$$NetworkFailureImplCopyWith(_$NetworkFailureImpl value,
          $Res Function(_$NetworkFailureImpl) then) =
      __$$NetworkFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$NetworkFailureImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$NetworkFailureImpl>
    implements _$$NetworkFailureImplCopyWith<$Res> {
  __$$NetworkFailureImplCopyWithImpl(
      _$NetworkFailureImpl _value, $Res Function(_$NetworkFailureImpl) _then)
      : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
  }) {
    return _then(_$NetworkFailureImpl(
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$NetworkFailureImpl implements NetworkFailure {
  const _$NetworkFailureImpl({this.message});

  @override
  final String? message;

  @override
  String toString() {
    return 'Failure.network(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NetworkFailureImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NetworkFailureImplCopyWith<_$NetworkFailureImpl> get copyWith =>
      __$$NetworkFailureImplCopyWithImpl<_$NetworkFailureImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? message) network,
    required TResult Function() timeout,
    required TResult Function(String? message) unauthorized,
    required TResult Function(String? message) forbidden,
    required TResult Function(String? message) notFound,
    required TResult Function(String? message) conflict,
    required TResult Function(String message, Map<String, String>? fields)
        validation,
    required TResult Function(String? message) server,
    required TResult Function(String? message) unknown,
  }) {
    return network(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? message)? network,
    TResult? Function()? timeout,
    TResult? Function(String? message)? unauthorized,
    TResult? Function(String? message)? forbidden,
    TResult? Function(String? message)? notFound,
    TResult? Function(String? message)? conflict,
    TResult? Function(String message, Map<String, String>? fields)? validation,
    TResult? Function(String? message)? server,
    TResult? Function(String? message)? unknown,
  }) {
    return network?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? message)? network,
    TResult Function()? timeout,
    TResult Function(String? message)? unauthorized,
    TResult Function(String? message)? forbidden,
    TResult Function(String? message)? notFound,
    TResult Function(String? message)? conflict,
    TResult Function(String message, Map<String, String>? fields)? validation,
    TResult Function(String? message)? server,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (network != null) {
      return network(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkFailure value) network,
    required TResult Function(TimeoutFailure value) timeout,
    required TResult Function(UnauthorizedFailure value) unauthorized,
    required TResult Function(ForbiddenFailure value) forbidden,
    required TResult Function(NotFoundFailure value) notFound,
    required TResult Function(ConflictFailure value) conflict,
    required TResult Function(ValidationFailure value) validation,
    required TResult Function(ServerFailure value) server,
    required TResult Function(UnknownFailure value) unknown,
  }) {
    return network(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkFailure value)? network,
    TResult? Function(TimeoutFailure value)? timeout,
    TResult? Function(UnauthorizedFailure value)? unauthorized,
    TResult? Function(ForbiddenFailure value)? forbidden,
    TResult? Function(NotFoundFailure value)? notFound,
    TResult? Function(ConflictFailure value)? conflict,
    TResult? Function(ValidationFailure value)? validation,
    TResult? Function(ServerFailure value)? server,
    TResult? Function(UnknownFailure value)? unknown,
  }) {
    return network?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkFailure value)? network,
    TResult Function(TimeoutFailure value)? timeout,
    TResult Function(UnauthorizedFailure value)? unauthorized,
    TResult Function(ForbiddenFailure value)? forbidden,
    TResult Function(NotFoundFailure value)? notFound,
    TResult Function(ConflictFailure value)? conflict,
    TResult Function(ValidationFailure value)? validation,
    TResult Function(ServerFailure value)? server,
    TResult Function(UnknownFailure value)? unknown,
    required TResult orElse(),
  }) {
    if (network != null) {
      return network(this);
    }
    return orElse();
  }
}

abstract class NetworkFailure implements Failure {
  const factory NetworkFailure({final String? message}) = _$NetworkFailureImpl;

  String? get message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NetworkFailureImplCopyWith<_$NetworkFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TimeoutFailureImplCopyWith<$Res> {
  factory _$$TimeoutFailureImplCopyWith(_$TimeoutFailureImpl value,
          $Res Function(_$TimeoutFailureImpl) then) =
      __$$TimeoutFailureImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$TimeoutFailureImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$TimeoutFailureImpl>
    implements _$$TimeoutFailureImplCopyWith<$Res> {
  __$$TimeoutFailureImplCopyWithImpl(
      _$TimeoutFailureImpl _value, $Res Function(_$TimeoutFailureImpl) _then)
      : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$TimeoutFailureImpl implements TimeoutFailure {
  const _$TimeoutFailureImpl();

  @override
  String toString() {
    return 'Failure.timeout()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$TimeoutFailureImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? message) network,
    required TResult Function() timeout,
    required TResult Function(String? message) unauthorized,
    required TResult Function(String? message) forbidden,
    required TResult Function(String? message) notFound,
    required TResult Function(String? message) conflict,
    required TResult Function(String message, Map<String, String>? fields)
        validation,
    required TResult Function(String? message) server,
    required TResult Function(String? message) unknown,
  }) {
    return timeout();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? message)? network,
    TResult? Function()? timeout,
    TResult? Function(String? message)? unauthorized,
    TResult? Function(String? message)? forbidden,
    TResult? Function(String? message)? notFound,
    TResult? Function(String? message)? conflict,
    TResult? Function(String message, Map<String, String>? fields)? validation,
    TResult? Function(String? message)? server,
    TResult? Function(String? message)? unknown,
  }) {
    return timeout?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? message)? network,
    TResult Function()? timeout,
    TResult Function(String? message)? unauthorized,
    TResult Function(String? message)? forbidden,
    TResult Function(String? message)? notFound,
    TResult Function(String? message)? conflict,
    TResult Function(String message, Map<String, String>? fields)? validation,
    TResult Function(String? message)? server,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (timeout != null) {
      return timeout();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkFailure value) network,
    required TResult Function(TimeoutFailure value) timeout,
    required TResult Function(UnauthorizedFailure value) unauthorized,
    required TResult Function(ForbiddenFailure value) forbidden,
    required TResult Function(NotFoundFailure value) notFound,
    required TResult Function(ConflictFailure value) conflict,
    required TResult Function(ValidationFailure value) validation,
    required TResult Function(ServerFailure value) server,
    required TResult Function(UnknownFailure value) unknown,
  }) {
    return timeout(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkFailure value)? network,
    TResult? Function(TimeoutFailure value)? timeout,
    TResult? Function(UnauthorizedFailure value)? unauthorized,
    TResult? Function(ForbiddenFailure value)? forbidden,
    TResult? Function(NotFoundFailure value)? notFound,
    TResult? Function(ConflictFailure value)? conflict,
    TResult? Function(ValidationFailure value)? validation,
    TResult? Function(ServerFailure value)? server,
    TResult? Function(UnknownFailure value)? unknown,
  }) {
    return timeout?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkFailure value)? network,
    TResult Function(TimeoutFailure value)? timeout,
    TResult Function(UnauthorizedFailure value)? unauthorized,
    TResult Function(ForbiddenFailure value)? forbidden,
    TResult Function(NotFoundFailure value)? notFound,
    TResult Function(ConflictFailure value)? conflict,
    TResult Function(ValidationFailure value)? validation,
    TResult Function(ServerFailure value)? server,
    TResult Function(UnknownFailure value)? unknown,
    required TResult orElse(),
  }) {
    if (timeout != null) {
      return timeout(this);
    }
    return orElse();
  }
}

abstract class TimeoutFailure implements Failure {
  const factory TimeoutFailure() = _$TimeoutFailureImpl;
}

/// @nodoc
abstract class _$$UnauthorizedFailureImplCopyWith<$Res> {
  factory _$$UnauthorizedFailureImplCopyWith(_$UnauthorizedFailureImpl value,
          $Res Function(_$UnauthorizedFailureImpl) then) =
      __$$UnauthorizedFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$UnauthorizedFailureImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$UnauthorizedFailureImpl>
    implements _$$UnauthorizedFailureImplCopyWith<$Res> {
  __$$UnauthorizedFailureImplCopyWithImpl(_$UnauthorizedFailureImpl _value,
      $Res Function(_$UnauthorizedFailureImpl) _then)
      : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
  }) {
    return _then(_$UnauthorizedFailureImpl(
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$UnauthorizedFailureImpl implements UnauthorizedFailure {
  const _$UnauthorizedFailureImpl({this.message});

  @override
  final String? message;

  @override
  String toString() {
    return 'Failure.unauthorized(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnauthorizedFailureImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnauthorizedFailureImplCopyWith<_$UnauthorizedFailureImpl> get copyWith =>
      __$$UnauthorizedFailureImplCopyWithImpl<_$UnauthorizedFailureImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? message) network,
    required TResult Function() timeout,
    required TResult Function(String? message) unauthorized,
    required TResult Function(String? message) forbidden,
    required TResult Function(String? message) notFound,
    required TResult Function(String? message) conflict,
    required TResult Function(String message, Map<String, String>? fields)
        validation,
    required TResult Function(String? message) server,
    required TResult Function(String? message) unknown,
  }) {
    return unauthorized(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? message)? network,
    TResult? Function()? timeout,
    TResult? Function(String? message)? unauthorized,
    TResult? Function(String? message)? forbidden,
    TResult? Function(String? message)? notFound,
    TResult? Function(String? message)? conflict,
    TResult? Function(String message, Map<String, String>? fields)? validation,
    TResult? Function(String? message)? server,
    TResult? Function(String? message)? unknown,
  }) {
    return unauthorized?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? message)? network,
    TResult Function()? timeout,
    TResult Function(String? message)? unauthorized,
    TResult Function(String? message)? forbidden,
    TResult Function(String? message)? notFound,
    TResult Function(String? message)? conflict,
    TResult Function(String message, Map<String, String>? fields)? validation,
    TResult Function(String? message)? server,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (unauthorized != null) {
      return unauthorized(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkFailure value) network,
    required TResult Function(TimeoutFailure value) timeout,
    required TResult Function(UnauthorizedFailure value) unauthorized,
    required TResult Function(ForbiddenFailure value) forbidden,
    required TResult Function(NotFoundFailure value) notFound,
    required TResult Function(ConflictFailure value) conflict,
    required TResult Function(ValidationFailure value) validation,
    required TResult Function(ServerFailure value) server,
    required TResult Function(UnknownFailure value) unknown,
  }) {
    return unauthorized(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkFailure value)? network,
    TResult? Function(TimeoutFailure value)? timeout,
    TResult? Function(UnauthorizedFailure value)? unauthorized,
    TResult? Function(ForbiddenFailure value)? forbidden,
    TResult? Function(NotFoundFailure value)? notFound,
    TResult? Function(ConflictFailure value)? conflict,
    TResult? Function(ValidationFailure value)? validation,
    TResult? Function(ServerFailure value)? server,
    TResult? Function(UnknownFailure value)? unknown,
  }) {
    return unauthorized?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkFailure value)? network,
    TResult Function(TimeoutFailure value)? timeout,
    TResult Function(UnauthorizedFailure value)? unauthorized,
    TResult Function(ForbiddenFailure value)? forbidden,
    TResult Function(NotFoundFailure value)? notFound,
    TResult Function(ConflictFailure value)? conflict,
    TResult Function(ValidationFailure value)? validation,
    TResult Function(ServerFailure value)? server,
    TResult Function(UnknownFailure value)? unknown,
    required TResult orElse(),
  }) {
    if (unauthorized != null) {
      return unauthorized(this);
    }
    return orElse();
  }
}

abstract class UnauthorizedFailure implements Failure {
  const factory UnauthorizedFailure({final String? message}) =
      _$UnauthorizedFailureImpl;

  String? get message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnauthorizedFailureImplCopyWith<_$UnauthorizedFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ForbiddenFailureImplCopyWith<$Res> {
  factory _$$ForbiddenFailureImplCopyWith(_$ForbiddenFailureImpl value,
          $Res Function(_$ForbiddenFailureImpl) then) =
      __$$ForbiddenFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$ForbiddenFailureImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$ForbiddenFailureImpl>
    implements _$$ForbiddenFailureImplCopyWith<$Res> {
  __$$ForbiddenFailureImplCopyWithImpl(_$ForbiddenFailureImpl _value,
      $Res Function(_$ForbiddenFailureImpl) _then)
      : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
  }) {
    return _then(_$ForbiddenFailureImpl(
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ForbiddenFailureImpl implements ForbiddenFailure {
  const _$ForbiddenFailureImpl({this.message});

  @override
  final String? message;

  @override
  String toString() {
    return 'Failure.forbidden(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ForbiddenFailureImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ForbiddenFailureImplCopyWith<_$ForbiddenFailureImpl> get copyWith =>
      __$$ForbiddenFailureImplCopyWithImpl<_$ForbiddenFailureImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? message) network,
    required TResult Function() timeout,
    required TResult Function(String? message) unauthorized,
    required TResult Function(String? message) forbidden,
    required TResult Function(String? message) notFound,
    required TResult Function(String? message) conflict,
    required TResult Function(String message, Map<String, String>? fields)
        validation,
    required TResult Function(String? message) server,
    required TResult Function(String? message) unknown,
  }) {
    return forbidden(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? message)? network,
    TResult? Function()? timeout,
    TResult? Function(String? message)? unauthorized,
    TResult? Function(String? message)? forbidden,
    TResult? Function(String? message)? notFound,
    TResult? Function(String? message)? conflict,
    TResult? Function(String message, Map<String, String>? fields)? validation,
    TResult? Function(String? message)? server,
    TResult? Function(String? message)? unknown,
  }) {
    return forbidden?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? message)? network,
    TResult Function()? timeout,
    TResult Function(String? message)? unauthorized,
    TResult Function(String? message)? forbidden,
    TResult Function(String? message)? notFound,
    TResult Function(String? message)? conflict,
    TResult Function(String message, Map<String, String>? fields)? validation,
    TResult Function(String? message)? server,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (forbidden != null) {
      return forbidden(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkFailure value) network,
    required TResult Function(TimeoutFailure value) timeout,
    required TResult Function(UnauthorizedFailure value) unauthorized,
    required TResult Function(ForbiddenFailure value) forbidden,
    required TResult Function(NotFoundFailure value) notFound,
    required TResult Function(ConflictFailure value) conflict,
    required TResult Function(ValidationFailure value) validation,
    required TResult Function(ServerFailure value) server,
    required TResult Function(UnknownFailure value) unknown,
  }) {
    return forbidden(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkFailure value)? network,
    TResult? Function(TimeoutFailure value)? timeout,
    TResult? Function(UnauthorizedFailure value)? unauthorized,
    TResult? Function(ForbiddenFailure value)? forbidden,
    TResult? Function(NotFoundFailure value)? notFound,
    TResult? Function(ConflictFailure value)? conflict,
    TResult? Function(ValidationFailure value)? validation,
    TResult? Function(ServerFailure value)? server,
    TResult? Function(UnknownFailure value)? unknown,
  }) {
    return forbidden?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkFailure value)? network,
    TResult Function(TimeoutFailure value)? timeout,
    TResult Function(UnauthorizedFailure value)? unauthorized,
    TResult Function(ForbiddenFailure value)? forbidden,
    TResult Function(NotFoundFailure value)? notFound,
    TResult Function(ConflictFailure value)? conflict,
    TResult Function(ValidationFailure value)? validation,
    TResult Function(ServerFailure value)? server,
    TResult Function(UnknownFailure value)? unknown,
    required TResult orElse(),
  }) {
    if (forbidden != null) {
      return forbidden(this);
    }
    return orElse();
  }
}

abstract class ForbiddenFailure implements Failure {
  const factory ForbiddenFailure({final String? message}) =
      _$ForbiddenFailureImpl;

  String? get message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ForbiddenFailureImplCopyWith<_$ForbiddenFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NotFoundFailureImplCopyWith<$Res> {
  factory _$$NotFoundFailureImplCopyWith(_$NotFoundFailureImpl value,
          $Res Function(_$NotFoundFailureImpl) then) =
      __$$NotFoundFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$NotFoundFailureImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$NotFoundFailureImpl>
    implements _$$NotFoundFailureImplCopyWith<$Res> {
  __$$NotFoundFailureImplCopyWithImpl(
      _$NotFoundFailureImpl _value, $Res Function(_$NotFoundFailureImpl) _then)
      : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
  }) {
    return _then(_$NotFoundFailureImpl(
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$NotFoundFailureImpl implements NotFoundFailure {
  const _$NotFoundFailureImpl({this.message});

  @override
  final String? message;

  @override
  String toString() {
    return 'Failure.notFound(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotFoundFailureImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotFoundFailureImplCopyWith<_$NotFoundFailureImpl> get copyWith =>
      __$$NotFoundFailureImplCopyWithImpl<_$NotFoundFailureImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? message) network,
    required TResult Function() timeout,
    required TResult Function(String? message) unauthorized,
    required TResult Function(String? message) forbidden,
    required TResult Function(String? message) notFound,
    required TResult Function(String? message) conflict,
    required TResult Function(String message, Map<String, String>? fields)
        validation,
    required TResult Function(String? message) server,
    required TResult Function(String? message) unknown,
  }) {
    return notFound(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? message)? network,
    TResult? Function()? timeout,
    TResult? Function(String? message)? unauthorized,
    TResult? Function(String? message)? forbidden,
    TResult? Function(String? message)? notFound,
    TResult? Function(String? message)? conflict,
    TResult? Function(String message, Map<String, String>? fields)? validation,
    TResult? Function(String? message)? server,
    TResult? Function(String? message)? unknown,
  }) {
    return notFound?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? message)? network,
    TResult Function()? timeout,
    TResult Function(String? message)? unauthorized,
    TResult Function(String? message)? forbidden,
    TResult Function(String? message)? notFound,
    TResult Function(String? message)? conflict,
    TResult Function(String message, Map<String, String>? fields)? validation,
    TResult Function(String? message)? server,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (notFound != null) {
      return notFound(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkFailure value) network,
    required TResult Function(TimeoutFailure value) timeout,
    required TResult Function(UnauthorizedFailure value) unauthorized,
    required TResult Function(ForbiddenFailure value) forbidden,
    required TResult Function(NotFoundFailure value) notFound,
    required TResult Function(ConflictFailure value) conflict,
    required TResult Function(ValidationFailure value) validation,
    required TResult Function(ServerFailure value) server,
    required TResult Function(UnknownFailure value) unknown,
  }) {
    return notFound(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkFailure value)? network,
    TResult? Function(TimeoutFailure value)? timeout,
    TResult? Function(UnauthorizedFailure value)? unauthorized,
    TResult? Function(ForbiddenFailure value)? forbidden,
    TResult? Function(NotFoundFailure value)? notFound,
    TResult? Function(ConflictFailure value)? conflict,
    TResult? Function(ValidationFailure value)? validation,
    TResult? Function(ServerFailure value)? server,
    TResult? Function(UnknownFailure value)? unknown,
  }) {
    return notFound?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkFailure value)? network,
    TResult Function(TimeoutFailure value)? timeout,
    TResult Function(UnauthorizedFailure value)? unauthorized,
    TResult Function(ForbiddenFailure value)? forbidden,
    TResult Function(NotFoundFailure value)? notFound,
    TResult Function(ConflictFailure value)? conflict,
    TResult Function(ValidationFailure value)? validation,
    TResult Function(ServerFailure value)? server,
    TResult Function(UnknownFailure value)? unknown,
    required TResult orElse(),
  }) {
    if (notFound != null) {
      return notFound(this);
    }
    return orElse();
  }
}

abstract class NotFoundFailure implements Failure {
  const factory NotFoundFailure({final String? message}) =
      _$NotFoundFailureImpl;

  String? get message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotFoundFailureImplCopyWith<_$NotFoundFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ConflictFailureImplCopyWith<$Res> {
  factory _$$ConflictFailureImplCopyWith(_$ConflictFailureImpl value,
          $Res Function(_$ConflictFailureImpl) then) =
      __$$ConflictFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$ConflictFailureImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$ConflictFailureImpl>
    implements _$$ConflictFailureImplCopyWith<$Res> {
  __$$ConflictFailureImplCopyWithImpl(
      _$ConflictFailureImpl _value, $Res Function(_$ConflictFailureImpl) _then)
      : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
  }) {
    return _then(_$ConflictFailureImpl(
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ConflictFailureImpl implements ConflictFailure {
  const _$ConflictFailureImpl({this.message});

  @override
  final String? message;

  @override
  String toString() {
    return 'Failure.conflict(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConflictFailureImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConflictFailureImplCopyWith<_$ConflictFailureImpl> get copyWith =>
      __$$ConflictFailureImplCopyWithImpl<_$ConflictFailureImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? message) network,
    required TResult Function() timeout,
    required TResult Function(String? message) unauthorized,
    required TResult Function(String? message) forbidden,
    required TResult Function(String? message) notFound,
    required TResult Function(String? message) conflict,
    required TResult Function(String message, Map<String, String>? fields)
        validation,
    required TResult Function(String? message) server,
    required TResult Function(String? message) unknown,
  }) {
    return conflict(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? message)? network,
    TResult? Function()? timeout,
    TResult? Function(String? message)? unauthorized,
    TResult? Function(String? message)? forbidden,
    TResult? Function(String? message)? notFound,
    TResult? Function(String? message)? conflict,
    TResult? Function(String message, Map<String, String>? fields)? validation,
    TResult? Function(String? message)? server,
    TResult? Function(String? message)? unknown,
  }) {
    return conflict?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? message)? network,
    TResult Function()? timeout,
    TResult Function(String? message)? unauthorized,
    TResult Function(String? message)? forbidden,
    TResult Function(String? message)? notFound,
    TResult Function(String? message)? conflict,
    TResult Function(String message, Map<String, String>? fields)? validation,
    TResult Function(String? message)? server,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (conflict != null) {
      return conflict(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkFailure value) network,
    required TResult Function(TimeoutFailure value) timeout,
    required TResult Function(UnauthorizedFailure value) unauthorized,
    required TResult Function(ForbiddenFailure value) forbidden,
    required TResult Function(NotFoundFailure value) notFound,
    required TResult Function(ConflictFailure value) conflict,
    required TResult Function(ValidationFailure value) validation,
    required TResult Function(ServerFailure value) server,
    required TResult Function(UnknownFailure value) unknown,
  }) {
    return conflict(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkFailure value)? network,
    TResult? Function(TimeoutFailure value)? timeout,
    TResult? Function(UnauthorizedFailure value)? unauthorized,
    TResult? Function(ForbiddenFailure value)? forbidden,
    TResult? Function(NotFoundFailure value)? notFound,
    TResult? Function(ConflictFailure value)? conflict,
    TResult? Function(ValidationFailure value)? validation,
    TResult? Function(ServerFailure value)? server,
    TResult? Function(UnknownFailure value)? unknown,
  }) {
    return conflict?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkFailure value)? network,
    TResult Function(TimeoutFailure value)? timeout,
    TResult Function(UnauthorizedFailure value)? unauthorized,
    TResult Function(ForbiddenFailure value)? forbidden,
    TResult Function(NotFoundFailure value)? notFound,
    TResult Function(ConflictFailure value)? conflict,
    TResult Function(ValidationFailure value)? validation,
    TResult Function(ServerFailure value)? server,
    TResult Function(UnknownFailure value)? unknown,
    required TResult orElse(),
  }) {
    if (conflict != null) {
      return conflict(this);
    }
    return orElse();
  }
}

abstract class ConflictFailure implements Failure {
  const factory ConflictFailure({final String? message}) =
      _$ConflictFailureImpl;

  String? get message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConflictFailureImplCopyWith<_$ConflictFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ValidationFailureImplCopyWith<$Res> {
  factory _$$ValidationFailureImplCopyWith(_$ValidationFailureImpl value,
          $Res Function(_$ValidationFailureImpl) then) =
      __$$ValidationFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message, Map<String, String>? fields});
}

/// @nodoc
class __$$ValidationFailureImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$ValidationFailureImpl>
    implements _$$ValidationFailureImplCopyWith<$Res> {
  __$$ValidationFailureImplCopyWithImpl(_$ValidationFailureImpl _value,
      $Res Function(_$ValidationFailureImpl) _then)
      : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? fields = freezed,
  }) {
    return _then(_$ValidationFailureImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      fields: freezed == fields
          ? _value._fields
          : fields // ignore: cast_nullable_to_non_nullable
              as Map<String, String>?,
    ));
  }
}

/// @nodoc

class _$ValidationFailureImpl implements ValidationFailure {
  const _$ValidationFailureImpl(
      {required this.message, final Map<String, String>? fields})
      : _fields = fields;

  @override
  final String message;
  final Map<String, String>? _fields;
  @override
  Map<String, String>? get fields {
    final value = _fields;
    if (value == null) return null;
    if (_fields is EqualUnmodifiableMapView) return _fields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'Failure.validation(message: $message, fields: $fields)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ValidationFailureImpl &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(other._fields, _fields));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, message, const DeepCollectionEquality().hash(_fields));

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ValidationFailureImplCopyWith<_$ValidationFailureImpl> get copyWith =>
      __$$ValidationFailureImplCopyWithImpl<_$ValidationFailureImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? message) network,
    required TResult Function() timeout,
    required TResult Function(String? message) unauthorized,
    required TResult Function(String? message) forbidden,
    required TResult Function(String? message) notFound,
    required TResult Function(String? message) conflict,
    required TResult Function(String message, Map<String, String>? fields)
        validation,
    required TResult Function(String? message) server,
    required TResult Function(String? message) unknown,
  }) {
    return validation(message, fields);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? message)? network,
    TResult? Function()? timeout,
    TResult? Function(String? message)? unauthorized,
    TResult? Function(String? message)? forbidden,
    TResult? Function(String? message)? notFound,
    TResult? Function(String? message)? conflict,
    TResult? Function(String message, Map<String, String>? fields)? validation,
    TResult? Function(String? message)? server,
    TResult? Function(String? message)? unknown,
  }) {
    return validation?.call(message, fields);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? message)? network,
    TResult Function()? timeout,
    TResult Function(String? message)? unauthorized,
    TResult Function(String? message)? forbidden,
    TResult Function(String? message)? notFound,
    TResult Function(String? message)? conflict,
    TResult Function(String message, Map<String, String>? fields)? validation,
    TResult Function(String? message)? server,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (validation != null) {
      return validation(message, fields);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkFailure value) network,
    required TResult Function(TimeoutFailure value) timeout,
    required TResult Function(UnauthorizedFailure value) unauthorized,
    required TResult Function(ForbiddenFailure value) forbidden,
    required TResult Function(NotFoundFailure value) notFound,
    required TResult Function(ConflictFailure value) conflict,
    required TResult Function(ValidationFailure value) validation,
    required TResult Function(ServerFailure value) server,
    required TResult Function(UnknownFailure value) unknown,
  }) {
    return validation(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkFailure value)? network,
    TResult? Function(TimeoutFailure value)? timeout,
    TResult? Function(UnauthorizedFailure value)? unauthorized,
    TResult? Function(ForbiddenFailure value)? forbidden,
    TResult? Function(NotFoundFailure value)? notFound,
    TResult? Function(ConflictFailure value)? conflict,
    TResult? Function(ValidationFailure value)? validation,
    TResult? Function(ServerFailure value)? server,
    TResult? Function(UnknownFailure value)? unknown,
  }) {
    return validation?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkFailure value)? network,
    TResult Function(TimeoutFailure value)? timeout,
    TResult Function(UnauthorizedFailure value)? unauthorized,
    TResult Function(ForbiddenFailure value)? forbidden,
    TResult Function(NotFoundFailure value)? notFound,
    TResult Function(ConflictFailure value)? conflict,
    TResult Function(ValidationFailure value)? validation,
    TResult Function(ServerFailure value)? server,
    TResult Function(UnknownFailure value)? unknown,
    required TResult orElse(),
  }) {
    if (validation != null) {
      return validation(this);
    }
    return orElse();
  }
}

abstract class ValidationFailure implements Failure {
  const factory ValidationFailure(
      {required final String message,
      final Map<String, String>? fields}) = _$ValidationFailureImpl;

  String get message;
  Map<String, String>? get fields;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ValidationFailureImplCopyWith<_$ValidationFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ServerFailureImplCopyWith<$Res> {
  factory _$$ServerFailureImplCopyWith(
          _$ServerFailureImpl value, $Res Function(_$ServerFailureImpl) then) =
      __$$ServerFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$ServerFailureImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$ServerFailureImpl>
    implements _$$ServerFailureImplCopyWith<$Res> {
  __$$ServerFailureImplCopyWithImpl(
      _$ServerFailureImpl _value, $Res Function(_$ServerFailureImpl) _then)
      : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
  }) {
    return _then(_$ServerFailureImpl(
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ServerFailureImpl implements ServerFailure {
  const _$ServerFailureImpl({this.message});

  @override
  final String? message;

  @override
  String toString() {
    return 'Failure.server(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServerFailureImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServerFailureImplCopyWith<_$ServerFailureImpl> get copyWith =>
      __$$ServerFailureImplCopyWithImpl<_$ServerFailureImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? message) network,
    required TResult Function() timeout,
    required TResult Function(String? message) unauthorized,
    required TResult Function(String? message) forbidden,
    required TResult Function(String? message) notFound,
    required TResult Function(String? message) conflict,
    required TResult Function(String message, Map<String, String>? fields)
        validation,
    required TResult Function(String? message) server,
    required TResult Function(String? message) unknown,
  }) {
    return server(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? message)? network,
    TResult? Function()? timeout,
    TResult? Function(String? message)? unauthorized,
    TResult? Function(String? message)? forbidden,
    TResult? Function(String? message)? notFound,
    TResult? Function(String? message)? conflict,
    TResult? Function(String message, Map<String, String>? fields)? validation,
    TResult? Function(String? message)? server,
    TResult? Function(String? message)? unknown,
  }) {
    return server?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? message)? network,
    TResult Function()? timeout,
    TResult Function(String? message)? unauthorized,
    TResult Function(String? message)? forbidden,
    TResult Function(String? message)? notFound,
    TResult Function(String? message)? conflict,
    TResult Function(String message, Map<String, String>? fields)? validation,
    TResult Function(String? message)? server,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (server != null) {
      return server(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkFailure value) network,
    required TResult Function(TimeoutFailure value) timeout,
    required TResult Function(UnauthorizedFailure value) unauthorized,
    required TResult Function(ForbiddenFailure value) forbidden,
    required TResult Function(NotFoundFailure value) notFound,
    required TResult Function(ConflictFailure value) conflict,
    required TResult Function(ValidationFailure value) validation,
    required TResult Function(ServerFailure value) server,
    required TResult Function(UnknownFailure value) unknown,
  }) {
    return server(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkFailure value)? network,
    TResult? Function(TimeoutFailure value)? timeout,
    TResult? Function(UnauthorizedFailure value)? unauthorized,
    TResult? Function(ForbiddenFailure value)? forbidden,
    TResult? Function(NotFoundFailure value)? notFound,
    TResult? Function(ConflictFailure value)? conflict,
    TResult? Function(ValidationFailure value)? validation,
    TResult? Function(ServerFailure value)? server,
    TResult? Function(UnknownFailure value)? unknown,
  }) {
    return server?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkFailure value)? network,
    TResult Function(TimeoutFailure value)? timeout,
    TResult Function(UnauthorizedFailure value)? unauthorized,
    TResult Function(ForbiddenFailure value)? forbidden,
    TResult Function(NotFoundFailure value)? notFound,
    TResult Function(ConflictFailure value)? conflict,
    TResult Function(ValidationFailure value)? validation,
    TResult Function(ServerFailure value)? server,
    TResult Function(UnknownFailure value)? unknown,
    required TResult orElse(),
  }) {
    if (server != null) {
      return server(this);
    }
    return orElse();
  }
}

abstract class ServerFailure implements Failure {
  const factory ServerFailure({final String? message}) = _$ServerFailureImpl;

  String? get message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServerFailureImplCopyWith<_$ServerFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UnknownFailureImplCopyWith<$Res> {
  factory _$$UnknownFailureImplCopyWith(_$UnknownFailureImpl value,
          $Res Function(_$UnknownFailureImpl) then) =
      __$$UnknownFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$UnknownFailureImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$UnknownFailureImpl>
    implements _$$UnknownFailureImplCopyWith<$Res> {
  __$$UnknownFailureImplCopyWithImpl(
      _$UnknownFailureImpl _value, $Res Function(_$UnknownFailureImpl) _then)
      : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
  }) {
    return _then(_$UnknownFailureImpl(
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$UnknownFailureImpl implements UnknownFailure {
  const _$UnknownFailureImpl({this.message});

  @override
  final String? message;

  @override
  String toString() {
    return 'Failure.unknown(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnknownFailureImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnknownFailureImplCopyWith<_$UnknownFailureImpl> get copyWith =>
      __$$UnknownFailureImplCopyWithImpl<_$UnknownFailureImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? message) network,
    required TResult Function() timeout,
    required TResult Function(String? message) unauthorized,
    required TResult Function(String? message) forbidden,
    required TResult Function(String? message) notFound,
    required TResult Function(String? message) conflict,
    required TResult Function(String message, Map<String, String>? fields)
        validation,
    required TResult Function(String? message) server,
    required TResult Function(String? message) unknown,
  }) {
    return unknown(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? message)? network,
    TResult? Function()? timeout,
    TResult? Function(String? message)? unauthorized,
    TResult? Function(String? message)? forbidden,
    TResult? Function(String? message)? notFound,
    TResult? Function(String? message)? conflict,
    TResult? Function(String message, Map<String, String>? fields)? validation,
    TResult? Function(String? message)? server,
    TResult? Function(String? message)? unknown,
  }) {
    return unknown?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? message)? network,
    TResult Function()? timeout,
    TResult Function(String? message)? unauthorized,
    TResult Function(String? message)? forbidden,
    TResult Function(String? message)? notFound,
    TResult Function(String? message)? conflict,
    TResult Function(String message, Map<String, String>? fields)? validation,
    TResult Function(String? message)? server,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkFailure value) network,
    required TResult Function(TimeoutFailure value) timeout,
    required TResult Function(UnauthorizedFailure value) unauthorized,
    required TResult Function(ForbiddenFailure value) forbidden,
    required TResult Function(NotFoundFailure value) notFound,
    required TResult Function(ConflictFailure value) conflict,
    required TResult Function(ValidationFailure value) validation,
    required TResult Function(ServerFailure value) server,
    required TResult Function(UnknownFailure value) unknown,
  }) {
    return unknown(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkFailure value)? network,
    TResult? Function(TimeoutFailure value)? timeout,
    TResult? Function(UnauthorizedFailure value)? unauthorized,
    TResult? Function(ForbiddenFailure value)? forbidden,
    TResult? Function(NotFoundFailure value)? notFound,
    TResult? Function(ConflictFailure value)? conflict,
    TResult? Function(ValidationFailure value)? validation,
    TResult? Function(ServerFailure value)? server,
    TResult? Function(UnknownFailure value)? unknown,
  }) {
    return unknown?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkFailure value)? network,
    TResult Function(TimeoutFailure value)? timeout,
    TResult Function(UnauthorizedFailure value)? unauthorized,
    TResult Function(ForbiddenFailure value)? forbidden,
    TResult Function(NotFoundFailure value)? notFound,
    TResult Function(ConflictFailure value)? conflict,
    TResult Function(ValidationFailure value)? validation,
    TResult Function(ServerFailure value)? server,
    TResult Function(UnknownFailure value)? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(this);
    }
    return orElse();
  }
}

abstract class UnknownFailure implements Failure {
  const factory UnknownFailure({final String? message}) = _$UnknownFailureImpl;

  String? get message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnknownFailureImplCopyWith<_$UnknownFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
