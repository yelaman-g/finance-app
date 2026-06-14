import 'package:aifb/app/router/app_router.dart';
import 'package:aifb/app/theme/app_theme.dart';
import 'package:aifb/app/theme/theme_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AifbApp extends ConsumerWidget {
  const AifbApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final mode = prefs.hasValue ? ref.watch(themeModeProvider) : ThemeMode.system;
    return MaterialApp.router(
      title: 'AI Family Budget',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      routerConfig: router,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
