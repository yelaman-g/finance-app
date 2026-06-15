import 'package:aifb/core/errors/failure.dart';

extension FailureMessage on Failure {
  /// Returns a clean Russian user-facing message. Never contains exception names,
  /// codes, or `Failure(...)` debug dumps.
  String get userMessage {
    return switch (this) {
      ValidationFailure(:final message, :final fields) =>
        _validationMessage(message, fields),
      UnauthorizedFailure() => 'Требуется вход',
      ForbiddenFailure() => 'Недостаточно прав',
      NotFoundFailure() => 'Не найдено',
      ConflictFailure(:final message) =>
        (message != null && message.isNotEmpty) ? message : 'Запись уже существует',
      NetworkFailure() => 'Нет соединения с сервером',
      TimeoutFailure() => 'Превышено время ожидания',
      ServerFailure() => 'Ошибка сервера, попробуйте позже',
      UnknownFailure() => 'Что-то пошло не так',
    };
  }
}

String _validationMessage(String message, Map<String, String>? fields) {
  if (fields != null && fields.isNotEmpty) {
    return fields.entries
        .map((e) => '${_ruLabel(e.key)} — ${e.value}')
        .join('\n');
  }
  return message.isNotEmpty ? message : 'Проверьте введённые данные';
}

String _ruLabel(String key) {
  const labels = <String, String>{
    'amount': 'Сумма',
    'title': 'Название',
    'name': 'Имя',
    'fullName': 'Имя',
    'email': 'Email',
    'password': 'Пароль',
    'newPassword': 'Новый пароль',
    'refreshToken': 'Токен',
    'idToken': 'Токен',
    'token': 'Токен',
    'code': 'Код',
    'inviteCode': 'Код приглашения',
    'note': 'Заметка',
    'text': 'Текст',
    'message': 'Сообщение',
    'question': 'Вопрос',
    'eventName': 'Название события',
    'eventDate': 'Дата',
    'startDate': 'Дата',
    'occurredOn': 'Дата',
    'openDate': 'Дата открытия',
    'targetAmount': 'Целевая сумма',
    'notifyThresholdPercent': 'Порог уведомления',
    'recurInterval': 'Интервал повтора',
    'options': 'Варианты',
    'keyword': 'Ключевое слово',
    'categoryId': 'Категория',
    'groupId': 'Группа',
    'role': 'Роль',
    'emoji': 'Реакция',
    'content': 'Содержание',
    'icon': 'Иконка',
    'color': 'Цвет',
    'type': 'Тип',
    'messages': 'Сообщения',
  };
  return labels[key] ?? key;
}
