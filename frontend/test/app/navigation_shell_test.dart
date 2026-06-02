import 'package:aifb/app/shell/app_shell.dart';
import 'package:aifb/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('AppShell renders NavigationBar with tabs', (tester) async {
    final router = GoRouter(
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
    await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Главная'), findsOneWidget);
    expect(find.text('Ещё'), findsOneWidget);
  });
}
