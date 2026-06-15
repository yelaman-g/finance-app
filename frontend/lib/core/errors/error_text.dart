/// Чистый текст ошибки для UI без технической части.
///
/// Провайдеры данных бросают `Exception(failure.userMessage)`, поэтому в
/// `AsyncValue.when(error:)` приходит `Exception`, чей текст — уже готовое
/// русское сообщение (см. `FailureMessage.userMessage`). Здесь достаточно
/// срезать технический префикс «Exception: », который добавляет `toString()`.
String errorText(Object error) {
  final text = error.toString();
  const prefix = 'Exception: ';
  return text.startsWith(prefix) ? text.substring(prefix.length) : text;
}
