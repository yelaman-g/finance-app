import 'package:aifb/features/feed/data/dto/moment.dart';
import 'package:aifb/features/feed/domain/repositories/feed_repository.dart';
import 'package:aifb/features/feed/presentation/pages/feed_page.dart';
import 'package:aifb/features/feed/presentation/providers/feed_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements FeedRepository {
  @override
  Future<List<Moment>> list() async => [
        Moment(
          id: 'm1',
          authorId: 'u1',
          authorName: 'Алия',
          text: 'Привет от Алии!',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          likes: 2,
          likedByMe: false,
        ),
        Moment(
          id: 'm2',
          authorId: 'u2',
          authorName: 'Берик',
          text: 'Сообщение Берика',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          likes: 5,
          likedByMe: true,
        ),
      ];

  @override
  Future<Moment> post(String text) async => Moment(
        id: 'm3',
        authorId: 'u1',
        authorName: 'Алия',
        text: text,
        createdAt: DateTime.now(),
        likes: 0,
        likedByMe: false,
      );

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> like(String id) async {}

  @override
  Future<void> unlike(String id) async {}
}

void main() {
  testWidgets('FeedPage renders 2 moments with author names, text and like counts',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        feedRepositoryProvider.overrideWithValue(_FakeRepo()),
      ],
      child: const MaterialApp(home: FeedPage()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Семейная лента'), findsOneWidget);
    expect(find.text('Алия'), findsOneWidget);
    expect(find.text('Берик'), findsOneWidget);
    expect(find.text('Привет от Алии!'), findsOneWidget);
    expect(find.text('Сообщение Берика'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // likes count for m1
    expect(find.text('5'), findsOneWidget); // likes count for m2
  });

  testWidgets('FeedPage shows empty hint when list is empty', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        feedRepositoryProvider.overrideWithValue(_EmptyRepo()),
      ],
      child: const MaterialApp(home: FeedPage()),
    ));
    await tester.pumpAndSettle();

    expect(
      find.text('Лента пуста. Поделитесь первым моментом!'),
      findsOneWidget,
    );
  });
}

class _EmptyRepo implements FeedRepository {
  @override
  Future<List<Moment>> list() async => [];

  @override
  Future<Moment> post(String text) async => Moment(
        id: 'x',
        authorId: 'u',
        authorName: 'u',
        text: text,
        createdAt: DateTime.now(),
        likes: 0,
        likedByMe: false,
      );

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> like(String id) async {}

  @override
  Future<void> unlike(String id) async {}
}
