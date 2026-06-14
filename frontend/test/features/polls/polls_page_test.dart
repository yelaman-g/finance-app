import 'package:aifb/features/auth/domain/entities/auth_user.dart';
import 'package:aifb/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aifb/features/auth/presentation/state/auth_state.dart';
import 'package:aifb/features/polls/data/dto/poll.dart';
import 'package:aifb/features/polls/domain/repositories/poll_repository.dart';
import 'package:aifb/features/polls/presentation/pages/polls_page.dart';
import 'package:aifb/features/polls/presentation/providers/poll_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fake repo ─────────────────────────────────────────────────────────────────

class _FakePollRepo implements PollRepository {
  @override
  Future<List<Poll>> list() async => [
        const Poll(
          id: 'p1',
          question: 'Поедем на море?',
          closed: false,
          createdBy: 'other-user',
          options: [
            PollOption(id: 'o1', text: 'Да', votes: 5),
            PollOption(id: 'o2', text: 'Нет', votes: 2),
          ],
          myVoteOptionId: 'o1',
        ),
      ];

  @override
  Future<Poll> create(String question, List<String> options) async =>
      Poll(
        id: 'p2',
        question: question,
        closed: false,
        createdBy: 'u1',
        options: options
            .map((t) => PollOption(id: t, text: t, votes: 0))
            .toList(),
      );

  @override
  Future<void> vote(String pollId, String optionId) async {}

  @override
  Future<void> close(String pollId) async {}
}

// ── Fake auth notifier ────────────────────────────────────────────────────────

class _FakeAuthController extends StateNotifier<AuthState>
    implements AuthController {
  _FakeAuthController()
      : super(
          const AuthState.authenticated(
            AuthUser(
              id: 'u1',
              email: 'test@test.com',
              fullName: 'Test User',
              emailVerified: true,
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('PollsPage renders poll question and options', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pollRepositoryProvider.overrideWithValue(_FakePollRepo()),
          authControllerProvider
              .overrideWith((ref) => _FakeAuthController()),
        ],
        child: const MaterialApp(home: PollsPage()),
      ),
    );

    // Resolve the FutureProvider
    await tester.pumpAndSettle();

    expect(find.text('Голосования'), findsOneWidget);
    expect(find.text('Поедем на море?'), findsOneWidget);
    expect(find.text('Да'), findsOneWidget);
    expect(find.text('Нет'), findsOneWidget);
  });

  testWidgets('PollsPage shows empty hint when no polls', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pollRepositoryProvider.overrideWithValue(_EmptyPollRepo()),
          authControllerProvider
              .overrideWith((ref) => _FakeAuthController()),
        ],
        child: const MaterialApp(home: PollsPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Голосований пока нет. Создайте первое!'), findsOneWidget);
  });
}

class _EmptyPollRepo implements PollRepository {
  @override
  Future<List<Poll>> list() async => [];
  @override
  Future<Poll> create(String q, List<String> o) async =>
      Poll(id: 'x', question: q, closed: false, createdBy: 'u', options: []);
  @override
  Future<void> vote(String p, String o) async {}
  @override
  Future<void> close(String p) async {}
}
