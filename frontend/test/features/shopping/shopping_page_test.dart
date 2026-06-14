import 'package:aifb/features/shopping/data/dto/shopping_item.dart';
import 'package:aifb/features/shopping/domain/repositories/shopping_repository.dart';
import 'package:aifb/features/shopping/presentation/pages/shopping_page.dart';
import 'package:aifb/features/shopping/presentation/providers/shopping_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements ShoppingRepository {
  @override
  Future<List<ShoppingItem>> list() async => const [
        ShoppingItem(id: 's1', title: 'Молоко', checked: false, createdBy: 'u1'),
        ShoppingItem(id: 's2', title: 'Хлеб', checked: true, createdBy: 'u1'),
      ];

  @override
  Future<ShoppingItem> add(String title) async =>
      ShoppingItem(id: 's3', title: title, checked: false, createdBy: 'u1');

  @override
  Future<ShoppingItem> toggle(String id) async =>
      const ShoppingItem(id: 's1', title: 'Молоко', checked: true, createdBy: 'u1');

  @override
  Future<void> delete(String id) async {}
}

void main() {
  testWidgets('ShoppingPage renders items', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        shoppingRepositoryProvider.overrideWithValue(_FakeRepo()),
      ],
      child: const MaterialApp(home: ShoppingPage()),
    ));
    // Let the FutureProvider resolve
    await tester.pumpAndSettle();

    expect(find.text('Список покупок'), findsOneWidget);
    expect(find.text('Молоко'), findsOneWidget);
    expect(find.text('Хлеб'), findsOneWidget);
  });

  testWidgets('ShoppingPage shows empty hint when list is empty', (tester) async {
    final emptyRepo = _EmptyRepo();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        shoppingRepositoryProvider.overrideWithValue(emptyRepo),
      ],
      child: const MaterialApp(home: ShoppingPage()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Список пуст. Добавьте первый товар!'), findsOneWidget);
  });
}

class _EmptyRepo implements ShoppingRepository {
  @override
  Future<List<ShoppingItem>> list() async => const [];
  @override
  Future<ShoppingItem> add(String title) async =>
      ShoppingItem(id: 'x', title: title, checked: false, createdBy: 'u');
  @override
  Future<ShoppingItem> toggle(String id) async =>
      const ShoppingItem(id: 'x', title: '', checked: false, createdBy: 'u');
  @override
  Future<void> delete(String id) async {}
}
