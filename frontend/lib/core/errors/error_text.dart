import 'package:aifb/core/errors/failure.dart';
import 'package:aifb/core/errors/failure_message.dart';

/// Чистый текст ошибки для UI без технической части.
///
/// Работает независимо от того, что попало в `AsyncValue.when(error:)`:
/// - если это `Failure` (репозиторий пробросил его напрямую) — берём
///   готовое русское сообщение `userMessage`;
/// - если это `Exception(failure.userMessage)` (так делают data-провайдеры) —
///   срезаем технический префикс «Exception: », который добавляет `toString()`.
String errorText(Object error) {
  if (error is Failure) return error.userMessage;
  final text = error.toString();
  const prefix = 'Exception: ';
  return text.startsWith(prefix) ? text.substring(prefix.length) : text;
}
