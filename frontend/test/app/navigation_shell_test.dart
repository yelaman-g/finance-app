import 'package:aifb/app/shell/app_shell.dart';
import 'package:aifb/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _router() => GoRouter(
      initialLocation: '/a',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (ctx, state, shell) => AppShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(
                routes: [GoRoute(path: '/a', builder: (c, s) => const Text('A'))]),
            StatefulShellBranch(
                routes: [GoRoute(path: '/b', builder: (c, s) => const Text('B'))]),
            StatefulShellBranch(
                routes: [GoRoute(path: '/c', builder: (c, s) => const Text('C'))]),
            StatefulShellBranch(
                routes: [GoRoute(path: '/d', builder: (c, s) => const Text('D'))]),
            StatefulShellBranch(
                routes: [GoRoute(path: '/e', builder: (c, s) => const Text('E'))]),
          ],
        ),
      ],
    );

Widget _app(GoRouter router) => ProviderScope(
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );

void main() {
  testWidgets('AppShell renders NavigationBar with tabs', (tester) async {
    await tester.pumpWidget(_app(_router()));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Главная'), findsOneWidget);
    expect(find.text('Ещё'), findsOneWidget);
  });

  testWidgets('selecting a tab switches branch and refreshes without error',
      (tester) async {
    await tester.pumpWidget(_app(_router()));
    expect(find.text('A'), findsOneWidget);

    // Переключение вкладки вызывает goBranch + сброс провайдеров вкладки.
    await tester.tap(find.text('Операции'));
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);

    await tester.tap(find.text('Бюджеты'));
    await tester.pumpAndSettle();
    expect(find.text('C'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
