// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:aifb/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: AifbApp(),
      ),
    );

    // Pump a few bounded frames. We intentionally avoid pumpAndSettle():
    // the dashboard shows loading spinners while data providers resolve
    // network calls, which never settle without a backend in a unit test.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify that the app launches without errors.
    expect(find.byType(AifbApp), findsOneWidget);
  });
}
