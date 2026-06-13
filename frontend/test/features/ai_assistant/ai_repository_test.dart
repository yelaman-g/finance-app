import 'package:aifb/features/ai_assistant/data/dto/ai_dtos.dart';
import 'package:aifb/features/ai_assistant/data/data_sources/ai_remote_data_source.dart';
import 'package:aifb/features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart';
import 'package:aifb/features/ai_assistant/domain/entities/ai_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements AiRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late AiAssistantRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = AiAssistantRepositoryImpl(remote);
  });

  test('sendMessage forwards history and returns ai message', () async {
    final reply = AiMessage(
      id: '1', content: 'ответ', role: MessageRole.ai, timestamp: DateTime.now(),
    );
    when(() => remote.sendMessage('вопрос', any())).thenAnswer((_) async => reply);
    final res = await repo.sendMessage('вопрос', const []);
    expect(res.content, 'ответ');
  });

  test('createReminder builds body and returns reminder', () async {
    final r = Reminder(
      id: 'r1', eventName: 'ДР', eventDate: DateTime(2026, 9, 1),
      savedAmount: 0, daysUntil: 80, monthsRemaining: 3, monthlyNeeded: 1000, progressPercent: 0,
    );
    when(() => remote.createReminder(any())).thenAnswer((_) async => r);
    final res = await repo.createReminder(
        eventName: 'ДР', eventDate: DateTime(2026, 9, 1), targetAmount: 30000);
    expect(res.eventName, 'ДР');
    verify(() => remote.createReminder(any())).called(1);
  });
}
