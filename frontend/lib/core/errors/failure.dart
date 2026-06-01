import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

@freezed
sealed class Failure with _$Failure {
  const factory Failure.network({String? message}) = NetworkFailure;
  const factory Failure.timeout() = TimeoutFailure;
  const factory Failure.unauthorized({String? message}) = UnauthorizedFailure;
  const factory Failure.forbidden({String? message}) = ForbiddenFailure;
  const factory Failure.notFound({String? message}) = NotFoundFailure;
  const factory Failure.conflict({String? message}) = ConflictFailure;
  const factory Failure.validation({
    required String message,
    Map<String, String>? fields,
  }) = ValidationFailure;
  const factory Failure.server({String? message}) = ServerFailure;
  const factory Failure.unknown({String? message}) = UnknownFailure;
}
