import 'package:aifb/features/auth/domain/entities/auth_user.dart';
import 'package:aifb/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aifb/features/auth/presentation/state/auth_state.dart';
import 'package:aifb/features/wishlist/data/dto/wishlist_item.dart';
import 'package:aifb/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:aifb/features/wishlist/presentation/pages/wishlist_page.dart';
import 'package:aifb/features/wishlist/presentation/providers/wishlist_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake wishlist repository
// ---------------------------------------------------------------------------

class _FakeRepo implements WishlistRepository {
  @override
  Future<List<WishlistItem>> list() async => const [
        WishlistItem(
          id: 'w1',
          ownerId: 'u1',
          ownerName: 'Алия',
          title: 'Книга про Flutter',
          reserved: false,
        ),
        WishlistItem(
          id: 'w2',
          ownerId: 'u2',
          ownerName: 'Данияр',
          title: 'Наушники',
          reserved: false,
        ),
      ];

  @override
  Future<WishlistItem> add(String title, String? note) async => WishlistItem(
        id: 'w3',
        ownerId: 'u1',
        ownerName: 'Алия',
        title: title,
        reserved: false,
      );

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> reserve(String id) async {}

  @override
  Future<void> unreserve(String id) async {}
}

// ---------------------------------------------------------------------------
// Fake AuthController that starts in AuthAuthenticated state
// ---------------------------------------------------------------------------

class _FakeAuthController extends StateNotifier<AuthState>
    implements AuthController {
  _FakeAuthController()
      : super(
          const AuthState.authenticated(
            AuthUser(
              id: 'u1',
              email: 'aliya@example.com',
              fullName: 'Алия',
              emailVerified: true,
            ),
          ),
        );

  @override
  Future<void> logout() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('WishlistPage renders items grouped by owner', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wishlistRepositoryProvider.overrideWithValue(_FakeRepo()),
          authControllerProvider
              .overrideWith((ref) => _FakeAuthController()),
        ],
        child: const MaterialApp(home: WishlistPage()),
      ),
    );
    await tester.pumpAndSettle();

    // AppBar title
    expect(find.text('Вишлисты'), findsOneWidget);

    // Own section header
    expect(find.text('МОЙ СПИСОК'), findsOneWidget);

    // Other owner section header — ownerName uppercased
    expect(find.text('ДАНИЯР'), findsOneWidget);

    // Item titles
    expect(find.text('Книга про Flutter'), findsOneWidget);
    expect(find.text('Наушники'), findsOneWidget);
  });

  testWidgets('WishlistPage shows empty state when list is empty',
      (tester) async {
    final emptyRepo = _EmptyRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wishlistRepositoryProvider.overrideWithValue(emptyRepo),
          authControllerProvider
              .overrideWith((ref) => _FakeAuthController()),
        ],
        child: const MaterialApp(home: WishlistPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Вишлисты пусты. Добавьте первое желание!'),
        findsOneWidget);
  });
}

class _EmptyRepo implements WishlistRepository {
  @override
  Future<List<WishlistItem>> list() async => const [];

  @override
  Future<WishlistItem> add(String title, String? note) async => WishlistItem(
        id: 'x',
        ownerId: 'u1',
        ownerName: 'Test',
        title: title,
        reserved: false,
      );

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> reserve(String id) async {}

  @override
  Future<void> unreserve(String id) async {}
}
