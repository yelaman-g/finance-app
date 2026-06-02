// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'forgot_password_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ForgotPasswordState {
  ForgotStep get step => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String? get emailError => throw _privateConstructorUsedError;
  bool get submitting => throw _privateConstructorUsedError;
  String? get devCode => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  String? get codeError => throw _privateConstructorUsedError;
  String get newPassword => throw _privateConstructorUsedError;
  String? get newPasswordError => throw _privateConstructorUsedError;
  bool get resetSubmitting => throw _privateConstructorUsedError;
  bool get resetDone => throw _privateConstructorUsedError;
  Failure? get failure => throw _privateConstructorUsedError;

  /// Create a copy of ForgotPasswordState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ForgotPasswordStateCopyWith<ForgotPasswordState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ForgotPasswordStateCopyWith<$Res> {
  factory $ForgotPasswordStateCopyWith(
          ForgotPasswordState value, $Res Function(ForgotPasswordState) then) =
      _$ForgotPasswordStateCopyWithImpl<$Res, ForgotPasswordState>;
  @useResult
  $Res call(
      {ForgotStep step,
      String email,
      String? emailError,
      bool submitting,
      String? devCode,
      String code,
      String? codeError,
      String newPassword,
      String? newPasswordError,
      bool resetSubmitting,
      bool resetDone,
      Failure? failure});

  $FailureCopyWith<$Res>? get failure;
}

/// @nodoc
class _$ForgotPasswordStateCopyWithImpl<$Res, $Val extends ForgotPasswordState>
    implements $ForgotPasswordStateCopyWith<$Res> {
  _$ForgotPasswordStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ForgotPasswordState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? step = null,
    Object? email = null,
    Object? emailError = freezed,
    Object? submitting = null,
    Object? devCode = freezed,
    Object? code = null,
    Object? codeError = freezed,
    Object? newPassword = null,
    Object? newPasswordError = freezed,
    Object? resetSubmitting = null,
    Object? resetDone = null,
    Object? failure = freezed,
  }) {
    return _then(_value.copyWith(
      step: null == step
          ? _value.step
          : step // ignore: cast_nullable_to_non_nullable
              as ForgotStep,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      emailError: freezed == emailError
          ? _value.emailError
          : emailError // ignore: cast_nullable_to_non_nullable
              as String?,
      submitting: null == submitting
          ? _value.submitting
          : submitting // ignore: cast_nullable_to_non_nullable
              as bool,
      devCode: freezed == devCode
          ? _value.devCode
          : devCode // ignore: cast_nullable_to_non_nullable
              as String?,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      codeError: freezed == codeError
          ? _value.codeError
          : codeError // ignore: cast_nullable_to_non_nullable
              as String?,
      newPassword: null == newPassword
          ? _value.newPassword
          : newPassword // ignore: cast_nullable_to_non_nullable
              as String,
      newPasswordError: freezed == newPasswordError
          ? _value.newPasswordError
          : newPasswordError // ignore: cast_nullable_to_non_nullable
              as String?,
      resetSubmitting: null == resetSubmitting
          ? _value.resetSubmitting
          : resetSubmitting // ignore: cast_nullable_to_non_nullable
              as bool,
      resetDone: null == resetDone
          ? _value.resetDone
          : resetDone // ignore: cast_nullable_to_non_nullable
              as bool,
      failure: freezed == failure
          ? _value.failure
          : failure // ignore: cast_nullable_to_non_nullable
              as Failure?,
    ) as $Val);
  }

  /// Create a copy of ForgotPasswordState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FailureCopyWith<$Res>? get failure {
    if (_value.failure == null) {
      return null;
    }

    return $FailureCopyWith<$Res>(_value.failure!, (value) {
      return _then(_value.copyWith(failure: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ForgotPasswordStateImplCopyWith<$Res>
    implements $ForgotPasswordStateCopyWith<$Res> {
  factory _$$ForgotPasswordStateImplCopyWith(_$ForgotPasswordStateImpl value,
          $Res Function(_$ForgotPasswordStateImpl) then) =
      __$$ForgotPasswordStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ForgotStep step,
      String email,
      String? emailError,
      bool submitting,
      String? devCode,
      String code,
      String? codeError,
      String newPassword,
      String? newPasswordError,
      bool resetSubmitting,
      bool resetDone,
      Failure? failure});

  @override
  $FailureCopyWith<$Res>? get failure;
}

/// @nodoc
class __$$ForgotPasswordStateImplCopyWithImpl<$Res>
    extends _$ForgotPasswordStateCopyWithImpl<$Res, _$ForgotPasswordStateImpl>
    implements _$$ForgotPasswordStateImplCopyWith<$Res> {
  __$$ForgotPasswordStateImplCopyWithImpl(_$ForgotPasswordStateImpl _value,
      $Res Function(_$ForgotPasswordStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ForgotPasswordState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? step = null,
    Object? email = null,
    Object? emailError = freezed,
    Object? submitting = null,
    Object? devCode = freezed,
    Object? code = null,
    Object? codeError = freezed,
    Object? newPassword = null,
    Object? newPasswordError = freezed,
    Object? resetSubmitting = null,
    Object? resetDone = null,
    Object? failure = freezed,
  }) {
    return _then(_$ForgotPasswordStateImpl(
      step: null == step
          ? _value.step
          : step // ignore: cast_nullable_to_non_nullable
              as ForgotStep,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      emailError: freezed == emailError
          ? _value.emailError
          : emailError // ignore: cast_nullable_to_non_nullable
              as String?,
      submitting: null == submitting
          ? _value.submitting
          : submitting // ignore: cast_nullable_to_non_nullable
              as bool,
      devCode: freezed == devCode
          ? _value.devCode
          : devCode // ignore: cast_nullable_to_non_nullable
              as String?,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      codeError: freezed == codeError
          ? _value.codeError
          : codeError // ignore: cast_nullable_to_non_nullable
              as String?,
      newPassword: null == newPassword
          ? _value.newPassword
          : newPassword // ignore: cast_nullable_to_non_nullable
              as String,
      newPasswordError: freezed == newPasswordError
          ? _value.newPasswordError
          : newPasswordError // ignore: cast_nullable_to_non_nullable
              as String?,
      resetSubmitting: null == resetSubmitting
          ? _value.resetSubmitting
          : resetSubmitting // ignore: cast_nullable_to_non_nullable
              as bool,
      resetDone: null == resetDone
          ? _value.resetDone
          : resetDone // ignore: cast_nullable_to_non_nullable
              as bool,
      failure: freezed == failure
          ? _value.failure
          : failure // ignore: cast_nullable_to_non_nullable
              as Failure?,
    ));
  }
}

/// @nodoc

class _$ForgotPasswordStateImpl implements _ForgotPasswordState {
  const _$ForgotPasswordStateImpl(
      {this.step = ForgotStep.request,
      this.email = '',
      this.emailError,
      this.submitting = false,
      this.devCode,
      this.code = '',
      this.codeError,
      this.newPassword = '',
      this.newPasswordError,
      this.resetSubmitting = false,
      this.resetDone = false,
      this.failure});

  @override
  @JsonKey()
  final ForgotStep step;
  @override
  @JsonKey()
  final String email;
  @override
  final String? emailError;
  @override
  @JsonKey()
  final bool submitting;
  @override
  final String? devCode;
  @override
  @JsonKey()
  final String code;
  @override
  final String? codeError;
  @override
  @JsonKey()
  final String newPassword;
  @override
  final String? newPasswordError;
  @override
  @JsonKey()
  final bool resetSubmitting;
  @override
  @JsonKey()
  final bool resetDone;
  @override
  final Failure? failure;

  @override
  String toString() {
    return 'ForgotPasswordState(step: $step, email: $email, emailError: $emailError, submitting: $submitting, devCode: $devCode, code: $code, codeError: $codeError, newPassword: $newPassword, newPasswordError: $newPasswordError, resetSubmitting: $resetSubmitting, resetDone: $resetDone, failure: $failure)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ForgotPasswordStateImpl &&
            (identical(other.step, step) || other.step == step) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.emailError, emailError) ||
                other.emailError == emailError) &&
            (identical(other.submitting, submitting) ||
                other.submitting == submitting) &&
            (identical(other.devCode, devCode) || other.devCode == devCode) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.codeError, codeError) ||
                other.codeError == codeError) &&
            (identical(other.newPassword, newPassword) ||
                other.newPassword == newPassword) &&
            (identical(other.newPasswordError, newPasswordError) ||
                other.newPasswordError == newPasswordError) &&
            (identical(other.resetSubmitting, resetSubmitting) ||
                other.resetSubmitting == resetSubmitting) &&
            (identical(other.resetDone, resetDone) ||
                other.resetDone == resetDone) &&
            (identical(other.failure, failure) || other.failure == failure));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      step,
      email,
      emailError,
      submitting,
      devCode,
      code,
      codeError,
      newPassword,
      newPasswordError,
      resetSubmitting,
      resetDone,
      failure);

  /// Create a copy of ForgotPasswordState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ForgotPasswordStateImplCopyWith<_$ForgotPasswordStateImpl> get copyWith =>
      __$$ForgotPasswordStateImplCopyWithImpl<_$ForgotPasswordStateImpl>(
          this, _$identity);
}

abstract class _ForgotPasswordState implements ForgotPasswordState {
  const factory _ForgotPasswordState(
      {final ForgotStep step,
      final String email,
      final String? emailError,
      final bool submitting,
      final String? devCode,
      final String code,
      final String? codeError,
      final String newPassword,
      final String? newPasswordError,
      final bool resetSubmitting,
      final bool resetDone,
      final Failure? failure}) = _$ForgotPasswordStateImpl;

  @override
  ForgotStep get step;
  @override
  String get email;
  @override
  String? get emailError;
  @override
  bool get submitting;
  @override
  String? get devCode;
  @override
  String get code;
  @override
  String? get codeError;
  @override
  String get newPassword;
  @override
  String? get newPasswordError;
  @override
  bool get resetSubmitting;
  @override
  bool get resetDone;
  @override
  Failure? get failure;

  /// Create a copy of ForgotPasswordState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ForgotPasswordStateImplCopyWith<_$ForgotPasswordStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
