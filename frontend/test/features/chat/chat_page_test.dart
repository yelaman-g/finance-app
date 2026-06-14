import 'dart:async';

import 'package:aifb/features/auth/domain/entities/auth_user.dart';
import 'package:aifb/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aifb/features/auth/presentation/state/auth_state.dart';
import 'package:aifb/features/chat/data/chat_socket.dart';
import 'package:aifb/features/chat/data/dto/chat_message.dart';
import 'package:aifb/features/chat/domain/repositories/chat_repository.dart';
import 'package:aifb/features/chat/presentation/pages/chat_page.dart';
import 'package:aifb/features/chat/presentation/providers/chat_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fake ChatRepository ───────────────────────────────────────────────────────

final _now = DateTime(2025, 6, 1, 12);

class _FakeChatRepository implements ChatRepository {
  @override
  Future<List<ChatMessage>> history() async => [
        ChatMessage(
          id: 'msg-1',
          senderId: 'u1',
          senderName: 'Alice',
          text: 'Привет!',
          createdAt: _now,
        ),
        ChatMessage(
          id: 'msg-2',
          senderId: 'u2',
          senderName: 'Bob',
          text: 'Как дела?',
          createdAt: _now.add(const Duration(minutes: 1)),
        ),
      ];
}

// ── Fake ChatSocket ───────────────────────────────────────────────────────────

class _FakeChatSocket implements ChatSocket {
  final _controller = StreamController<ChatMessage>.broadcast();

  @override
  Stream<ChatMessage> get messages => _controller.stream;

  @override
  Future<void> connect() async {}

  @override
  void send(String text) {}

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

// ── Fake AuthController ───────────────────────────────────────────────────────

class _FakeAuthController extends StateNotifier<AuthState>
    implements AuthController {
  _FakeAuthController()
      : super(
          const AuthState.authenticated(
            AuthUser(
              id: 'u1',
              email: 'alice@test.com',
              fullName: 'Alice',
              emailVerified: true,
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('ChatPage renders 2 history messages without opening real socket',
      (tester) async {
    final fakeSocket = _FakeChatSocket();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider
              .overrideWithValue(_FakeChatRepository()),
          chatSocketProvider.overrideWith(
            (ref) async => fakeSocket,
          ),
          authControllerProvider
              .overrideWith((ref) => _FakeAuthController()),
        ],
        child: const MaterialApp(home: ChatPage()),
      ),
    );

    // Let futures resolve.
    await tester.pumpAndSettle();

    expect(find.text('Привет!'), findsOneWidget);
    expect(find.text('Как дела?'), findsOneWidget);

    await fakeSocket.dispose();
  });

  testWidgets('ChatPage shows empty hint when no messages', (tester) async {
    final fakeSocket = _FakeChatSocket();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWith((_) => _EmptyRepo()),
          chatSocketProvider.overrideWith((ref) async => fakeSocket),
          authControllerProvider
              .overrideWith((ref) => _FakeAuthController()),
        ],
        child: const MaterialApp(home: ChatPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Напишите первым'), findsOneWidget);

    await fakeSocket.dispose();
  });
}

class _EmptyRepo implements ChatRepository {
  @override
  Future<List<ChatMessage>> history() async => [];
}
