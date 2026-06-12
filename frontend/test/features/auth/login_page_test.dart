import 'package:aifb/app/theme/app_theme.dart';
import 'package:aifb/features/auth/presentation/pages/login_page.dart';
import 'package:aifb/shared/widgets/hig_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('показывает кнопку Google, форма email скрыта до клика по ссылке',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const LoginPage()),
      ),
    );

    expect(find.text('Войти через Google'), findsOneWidget);
    // классическая форма скрыта изначально
    expect(find.byType(HigTextField), findsNothing);

    await tester.tap(find.text('Войти с Email'));
    await tester.pumpAndSettle();

    // появились поля email + пароль
    expect(find.byType(HigTextField), findsNWidgets(2));
  });
}
