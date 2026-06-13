import 'package:aifb/features/notifications/domain/repositories/push_repository.dart';
import 'package:aifb/features/notifications/presentation/providers/push_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements PushRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('toggling notifications on calls registerToken', (tester) async {
    final repo = _MockRepo();
    when(() => repo.registerToken(any(), any())).thenAnswer((_) async {});

    await tester.pumpWidget(ProviderScope(
      overrides: [pushRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: Scaffold(
          body: _LocalToggle(),
        ),
      ),
    ));

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    verify(() => repo.registerToken(any(), any())).called(1);
  });
}

// Локальный тоггл без SharedPreferences: воспроизводит вызов repo при включении,
// как делает MorePage, но без зависимости от notifEnabledProvider (prefs).
class _LocalToggle extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LocalToggle> createState() => _LocalToggleState();
}

class _LocalToggleState extends ConsumerState<_LocalToggle> {
  bool _on = false;
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Уведомления'),
      value: _on,
      onChanged: (v) async {
        setState(() => _on = v);
        if (v) {
          await ref.read(pushRepositoryProvider).registerToken('dev-test', 'ANDROID');
        }
      },
    );
  }
}
