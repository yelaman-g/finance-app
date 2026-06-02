import 'package:aifb/app/theme/app_theme.dart';
import 'package:aifb/shared/widgets/hig_button.dart';
import 'package:aifb/shared/widgets/inset_section.dart';
import 'package:aifb/shared/widgets/large_title_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void main() {
  testWidgets('InsetSection renders header and tiles', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Scaffold(
          body: InsetSection(
            header: 'Раздел',
            children: [InsetTile(title: 'Строка 1'), InsetTile(title: 'Строка 2')],
          ),
        ),
      ),
    );
    expect(find.text('РАЗДЕЛ'), findsOneWidget);
    expect(find.text('Строка 1'), findsOneWidget);
    expect(find.text('Строка 2'), findsOneWidget);
  });

  testWidgets('HigButton fires onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(Scaffold(body: HigButton(label: 'OK', onPressed: () => tapped = true))),
    );
    await tester.tap(find.text('OK'));
    expect(tapped, isTrue);
  });

  testWidgets('LargeTitleScaffold shows title and content', (tester) async {
    await tester.pumpWidget(
      _wrap(const LargeTitleScaffold(title: 'Главная', slivers: [Text('контент')])),
    );
    expect(find.text('Главная'), findsWidgets);
    expect(find.text('контент'), findsOneWidget);
  });
}
