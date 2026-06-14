import 'package:aifb/features/auth/domain/entities/auth_user.dart';
import 'package:aifb/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aifb/features/auth/presentation/state/auth_state.dart';
import 'package:aifb/features/capsules/data/dto/capsule.dart';
import 'package:aifb/features/capsules/domain/repositories/capsule_repository.dart';
import 'package:aifb/features/capsules/presentation/pages/capsules_page.dart';
import 'package:aifb/features/capsules/presentation/providers/capsule_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fake repo (returns one locked + one opened capsule) ───────────────────────

class _FakeCapsuleRepo implements CapsuleRepository {
  @override
  Future<List<Capsule>> list() async => [
        Capsule(
          id: 'c1',
          title: 'Семье через 5 лет',
          openDate: DateTime(2030, 6, 1),
          locked: true,
          message: null,
          createdBy: 'other-user',
        ),
        Capsule(
          id: 'c2',
          title: 'Прошлогоднее',
          openDate: DateTime(2020, 1, 1),
          locked: false,
          message: 'Привет из прошлого!',
          createdBy: 'u1',
        ),
      ];

  @override
  Future<Capsule> create(
    String title,
    String message,
    DateTime openDate,
  ) async =>
      Capsule(
        id: 'c3',
        title: title,
        openDate: openDate,
        locked: true,
        message: null,
        createdBy: 'u1',
      );

  @override
  Future<void> delete(String id) async {}
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
  testWidgets('CapsulesPage shows locked capsule with «Откроется» and hides message',
      (tester) async {
    // Use only the locked capsule so the opened capsule message is absent
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          capsuleRepositoryProvider.overrideWithValue(_LockedOnlyCapsuleRepo()),
          authControllerProvider.overrideWith((ref) => _FakeAuthController()),
        ],
        child: const MaterialApp(home: CapsulesPage()),
      ),
    );

    await tester.pumpAndSettle();

    // Locked capsule: title visible, "Откроется" shown, message NOT shown
    expect(find.text('Семье через 5 лет'), findsOneWidget);
    expect(find.textContaining('Откроется'), findsOneWidget);
    // The secret message must be absent when capsule is locked
    expect(find.text('Секретное послание'), findsNothing);
  });

  testWidgets('CapsulesPage shows opened capsule with its message', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          capsuleRepositoryProvider.overrideWithValue(_FakeCapsuleRepo()),
          authControllerProvider.overrideWith((ref) => _FakeAuthController()),
        ],
        child: const MaterialApp(home: CapsulesPage()),
      ),
    );

    await tester.pumpAndSettle();

    // Opened capsule: title + message visible
    expect(find.text('Прошлогоднее'), findsOneWidget);
    expect(find.text('Привет из прошлого!'), findsOneWidget);
  });

  testWidgets('CapsulesPage shows empty hint when no capsules', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          capsuleRepositoryProvider.overrideWithValue(_EmptyCapsuleRepo()),
          authControllerProvider.overrideWith((ref) => _FakeAuthController()),
        ],
        child: const MaterialApp(home: CapsulesPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Капсул пока нет. Создайте первую!'), findsOneWidget);
  });
}

// Repo returning only a locked capsule (message hidden)
class _LockedOnlyCapsuleRepo implements CapsuleRepository {
  @override
  Future<List<Capsule>> list() async => [
        Capsule(
          id: 'c1',
          title: 'Семье через 5 лет',
          openDate: DateTime(2030, 6, 1),
          locked: true,
          message: 'Секретное послание',
          createdBy: 'other-user',
        ),
      ];

  @override
  Future<Capsule> create(String t, String m, DateTime d) async => Capsule(
        id: 'x',
        title: t,
        openDate: d,
        locked: true,
        createdBy: 'u',
      );

  @override
  Future<void> delete(String id) async {}
}

class _EmptyCapsuleRepo implements CapsuleRepository {
  @override
  Future<List<Capsule>> list() async => [];
  @override
  Future<Capsule> create(String t, String m, DateTime d) async => Capsule(
        id: 'x',
        title: t,
        openDate: d,
        locked: true,
        createdBy: 'u',
      );
  @override
  Future<void> delete(String id) async {}
}
