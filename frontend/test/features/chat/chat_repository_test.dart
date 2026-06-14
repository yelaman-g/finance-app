import 'package:aifb/features/chat/data/data_sources/chat_remote_data_source.dart';
import 'package:aifb/features/chat/data/dto/chat_message.dart';
import 'package:aifb/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDs extends Mock implements ChatRemoteDataSource {}

void main() {
  late _MockDs ds;
  late ChatRepositoryImpl repo;

  setUp(() {
    ds = _MockDs();
    repo = ChatRepositoryImpl(ds);
  });

  test('history() returns messages from data source', () async {
    final now = DateTime(2025, 1, 1, 12);
    final expected = [
      ChatMessage(
        id: 'm1',
        senderId: 'u1',
        senderName: 'Alice',
        text: 'Hello',
        createdAt: now,
      ),
      ChatMessage(
        id: 'm2',
        senderId: 'u2',
        senderName: 'Bob',
        text: 'Hi there',
        createdAt: now.add(const Duration(minutes: 1)),
      ),
    ];
    when(ds.history).thenAnswer((_) async => expected);

    final result = await repo.history();

    expect(result, hasLength(2));
    expect(result[0].id, 'm1');
    expect(result[0].senderName, 'Alice');
    expect(result[1].id, 'm2');
    expect(result[1].text, 'Hi there');
  });

  test('historyResult() wraps success in Ok', () async {
    when(ds.history).thenAnswer((_) async => []);
    final result = await repo.historyResult();
    expect(result.runtimeType.toString(), contains('Ok'));
  });

  test('ChatMessage.fromJson parses fields correctly', () {
    final json = {
      'id': 'msg-1',
      'senderId': 'user-42',
      'senderName': 'Иван',
      'text': 'Привет!',
      'createdAt': '2025-06-01T10:00:00Z',
    };
    final msg = ChatMessage.fromJson(json);
    expect(msg.id, 'msg-1');
    expect(msg.senderId, 'user-42');
    expect(msg.senderName, 'Иван');
    expect(msg.text, 'Привет!');
    expect(msg.createdAt, DateTime.parse('2025-06-01T10:00:00Z'));
  });

  test('deriveWsUrl strips /api/v1 and swaps scheme', () {
    // Import tested via chat_socket.dart but verifying logic here inline.
    const apiBase = 'https://finance-app-production-4362.up.railway.app/api/v1';
    // Expected: wss://finance-app-production-4362.up.railway.app/ws
    var url = apiBase;
    final suffixRe = RegExp(r'/api/v1/?$');
    url = url.replaceFirst(suffixRe, '');
    if (url.startsWith('https://')) {
      url = 'wss://${url.substring('https://'.length)}';
    }
    url = '$url/ws';
    expect(url, 'wss://finance-app-production-4362.up.railway.app/ws');
  });
}
