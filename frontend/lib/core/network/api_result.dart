import 'package:freezed_annotation/freezed_annotation.dart';

import '../errors/failure.dart';

part 'api_result.freezed.dart';

@Freezed(genericArgumentFactories: true)
sealed class Result<T> with _$Result<T> {
  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(Failure failure) = Err<T>;
}
