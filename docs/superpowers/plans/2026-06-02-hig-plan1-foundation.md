# План 1 — HIG-редизайн: фундамент (токены, тема, компоненты, навигация)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Заложить HIG-фундамент: шрифт Inter, системная палитра light/dark (через `HigColors` ThemeExtension), HIG-типографика и тема, набор общих компонентов (InsetSection/InsetTile/HigButton/HigTextField/LargeTitleScaffold) и навигационная оболочка с нижним таб-баром (5 вкладок + «Ещё»).

**Architecture:** Material 3 + Inter. Имена существующих токенов (`AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`) сохраняются (значения перекрашиваются в HIG), чтобы старые экраны компилировались до их переработки в Плане 2. Brightness-aware семантические цвета — через `ThemeExtension<HigColors>`, который читают новые компоненты. Навигация переводится на `StatefulShellRoute.indexedStack` с `NavigationBar`; вторичные экраны (family/groups/rules/admin/goal-detail) — push поверх оболочки, доступны из вкладки «Ещё».

**Tech Stack:** Flutter 3.44 / Dart 3.12, Material 3, go_router (StatefulShellRoute), Riverpod, `very_good_analysis`; тесты — flutter_test.

**Предусловие:** ветка `feature/hig-redesign` (от `feature/auto-categorization`). Существующие экраны и токены на месте.

---

## Структура файлов

**Создаваемые:**
- `frontend/assets/fonts/Inter.ttf` (переменный шрифт Inter)
- `frontend/lib/app/theme/hig_colors.dart` — `ThemeExtension<HigColors>` (light/dark)
- `frontend/lib/shared/widgets/inset_section.dart` — `InsetSection` + `InsetTile`
- `frontend/lib/shared/widgets/hig_button.dart` — `HigButton`
- `frontend/lib/shared/widgets/hig_text_field.dart` — `HigTextField`
- `frontend/lib/shared/widgets/large_title_scaffold.dart` — `LargeTitleScaffold`
- `frontend/lib/app/shell/app_shell.dart` — оболочка с `NavigationBar`
- `frontend/lib/features/more/presentation/pages/more_page.dart` — экран «Ещё»
- тесты: `test/shared/hig_components_test.dart`, `test/app/navigation_shell_test.dart`

**Изменяемые:**
- `frontend/pubspec.yaml` (fonts)
- `frontend/lib/app/theme/app_typography.dart` (Inter + HIG-шкала)
- `frontend/lib/app/theme/app_colors.dart` (HIG-значения, имена сохранены)
- `frontend/lib/app/theme/app_theme.dart` (HIG light/dark + `HigColors` + `NavigationBarTheme`)
- `frontend/lib/app/app.dart` (`themeMode` ← `themeModeProvider`, gating на prefs)
- `frontend/lib/app/router/routes.dart` (+`more`)
- `frontend/lib/app/router/app_router.dart` (StatefulShellRoute)

Команды — из `frontend/`. Гейт: `flutter analyze lib` 0 errors/warnings (info-хинты ок), `flutter test` зелёный, `flutter build web --no-tree-shake-icons` собирается.

---

## Task 1: Шрифт Inter + HIG-типографика + перекраска токенов

**Files:** `assets/fonts/Inter.ttf`; `pubspec.yaml`; `app_typography.dart`; `app_colors.dart`.

- [ ] **Step 1: Скачать Inter (переменный TTF).**
```bash
cd frontend && mkdir -p assets/fonts && \
curl -fsSL "https://raw.githubusercontent.com/google/fonts/main/ofl/inter/Inter%5Bopsz,wght%5D.ttf" -o assets/fonts/Inter.ttf && \
ls -l assets/fonts/Inter.ttf
```
Expected: файл > 300 КБ. Если загрузка не удалась (нет сети/404) — сообщить BLOCKED с текстом ошибки (не подменять другим шрифтом без согласования).

- [ ] **Step 2: Объявить шрифт в `pubspec.yaml`.** Replace the `flutter:` section:
```yaml
flutter:
  uses-material-design: true

  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter.ttf
```
Run `cd frontend && flutter pub get` → success.

- [ ] **Step 3: Переписать `lib/app/theme/app_typography.dart`** на Inter + HIG-шкалу (имена `display/h1/h2/title/body/caption/button` сохранены для совместимости; добавлены `headline/subhead/footnote`; цвет не зашиваем — задаёт тема):
```dart
import 'package:flutter/material.dart';

/// HIG-типографика на Inter. Цвет берётся из темы (textTheme/DefaultTextStyle).
class AppTypography {
  AppTypography._();

  static const String _family = 'Inter';

  static const TextStyle display = TextStyle(
      fontFamily: _family, fontSize: 34, height: 1.12, fontWeight: FontWeight.w700, letterSpacing: -0.4);
  static const TextStyle h1 = TextStyle(
      fontFamily: _family, fontSize: 28, height: 1.15, fontWeight: FontWeight.w700, letterSpacing: -0.3);
  static const TextStyle h2 = TextStyle(
      fontFamily: _family, fontSize: 22, height: 1.2, fontWeight: FontWeight.w700);
  static const TextStyle headline = TextStyle(
      fontFamily: _family, fontSize: 17, height: 1.3, fontWeight: FontWeight.w600);
  static const TextStyle title = TextStyle(
      fontFamily: _family, fontSize: 17, height: 1.3, fontWeight: FontWeight.w600);
  static const TextStyle body = TextStyle(
      fontFamily: _family, fontSize: 17, height: 1.4, fontWeight: FontWeight.w400);
  static const TextStyle subhead = TextStyle(
      fontFamily: _family, fontSize: 15, height: 1.35, fontWeight: FontWeight.w400);
  static const TextStyle caption = TextStyle(
      fontFamily: _family, fontSize: 12, height: 1.3, fontWeight: FontWeight.w400);
  static const TextStyle footnote = TextStyle(
      fontFamily: _family, fontSize: 13, height: 1.3, fontWeight: FontWeight.w400);
  static const TextStyle button = TextStyle(
      fontFamily: _family, fontSize: 17, fontWeight: FontWeight.w600);
}
```

- [ ] **Step 4: Перекрасить `lib/app/theme/app_colors.dart`** в HIG-палитру (имена сохранены, значения — light-HIG; добавлены новые семантические имена). Replace the whole file:
```dart
import 'package:flutter/material.dart';

/// HIG системная палитра (значения — для светлой темы; brightness-aware
/// семантика — в HigColors ThemeExtension). Имена сохранены для совместимости.
class AppColors {
  AppColors._();

  // Accent (системный синий)
  static const Color brand500 = Color(0xFF007AFF);
  static const Color brand600 = Color(0xFF0062CC);
  static const Color brand400 = Color(0xFF409CFF);
  static const Color brand100 = Color(0xFFD9ECFF);
  static const Color accent = brand500;

  // Метки/текст (light)
  static const Color graphite900 = Color(0xFF000000); // label
  static const Color graphite800 = Color(0xFF1C1C1E);
  static const Color graphite700 = Color(0xFF3C3C43); // ~secondary base
  static const Color graphite500 = Color(0x993C3C43); // secondaryLabel 60%
  static const Color graphite400 = Color(0x4D3C3C43); // tertiary 30%
  static const Color graphite300 = Color(0xFFC6C6C8);

  static const Color label = Color(0xFF000000);
  static const Color secondaryLabel = Color(0x993C3C43);
  static const Color separator = Color(0xFFC6C6C8);

  // Поверхности (light)
  static const Color gray100 = Color(0xFFF2F2F7); // page background
  static const Color gray50 = Color(0xFFF2F2F7);
  static const Color white = Color(0xFFFFFFFF); // card/section
  static const Color systemBackground = Color(0xFFF2F2F7);
  static const Color card = Color(0xFFFFFFFF);

  // Семантика
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color danger = Color(0xFFFF3B30);

  // Тени (мягкие, почти плоско)
  static const Color shadowSoft = Color(0x0F000000);
  static const Color shadowStrong = Color(0x1F000000);
}
```
(NOTE: `glassWhite`/`glassBorder` удалены — они использовались только в `glass_card.dart`, который мигрируется/удаляется в Плане 2. Если `flutter analyze` укажет на их использование вне glass_card — оставить эти два поля как `Color(0x00000000)`-заглушки и сообщить; но glass_card — единственный потребитель.)

- [ ] **Step 5: Проверка компиляции токенов.**
Run `cd frontend && flutter analyze lib/app/theme` — допустимы info-хинты; ошибок быть не должно. Если `glassWhite`/`glassBorder` всё же используются где-то ещё (кроме glass_card) — вернуть их как заглушки `static const Color glassWhite = Color(0x99FFFFFF); static const Color glassBorder = Color(0x33FFFFFF);` и сообщить в отчёте.

- [ ] **Step 6: Commit**
```bash
git add frontend/assets/fonts/Inter.ttf frontend/pubspec.yaml frontend/lib/app/theme/app_typography.dart frontend/lib/app/theme/app_colors.dart
git commit -m "feat(hig): шрифт Inter, HIG-типографика и системная палитра токенов"
```

---

## Task 2: HigColors (ThemeExtension), HIG-тема light/dark, wiring themeMode

**Files:** `hig_colors.dart`; `app_theme.dart`; `app.dart`.

- [ ] **Step 1: `lib/app/theme/hig_colors.dart`** — brightness-aware семантические цвета:
```dart
import 'package:flutter/material.dart';

/// HIG semantic colors, brightness-aware. Читается компонентами через
/// `Theme.of(context).extension<HigColors>()!`.
@immutable
class HigColors extends ThemeExtension<HigColors> {
  const HigColors({
    required this.pageBackground,
    required this.card,
    required this.label,
    required this.secondaryLabel,
    required this.separator,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color pageBackground;
  final Color card;
  final Color label;
  final Color secondaryLabel;
  final Color separator;
  final Color accent;
  final Color success;
  final Color warning;
  final Color danger;

  static const light = HigColors(
    pageBackground: Color(0xFFF2F2F7),
    card: Color(0xFFFFFFFF),
    label: Color(0xFF000000),
    secondaryLabel: Color(0x993C3C43),
    separator: Color(0xFFC6C6C8),
    accent: Color(0xFF007AFF),
    success: Color(0xFF34C759),
    warning: Color(0xFFFF9F0A),
    danger: Color(0xFFFF3B30),
  );

  static const dark = HigColors(
    pageBackground: Color(0xFF000000),
    card: Color(0xFF1C1C1E),
    label: Color(0xFFFFFFFF),
    secondaryLabel: Color(0x99EBEBF5),
    separator: Color(0xFF38383A),
    accent: Color(0xFF0A84FF),
    success: Color(0xFF30D158),
    warning: Color(0xFFFF9F0A),
    danger: Color(0xFFFF453A),
  );

  static HigColors of(BuildContext context) =>
      Theme.of(context).extension<HigColors>() ?? light;

  @override
  HigColors copyWith({
    Color? pageBackground,
    Color? card,
    Color? label,
    Color? secondaryLabel,
    Color? separator,
    Color? accent,
    Color? success,
    Color? warning,
    Color? danger,
  }) =>
      HigColors(
        pageBackground: pageBackground ?? this.pageBackground,
        card: card ?? this.card,
        label: label ?? this.label,
        secondaryLabel: secondaryLabel ?? this.secondaryLabel,
        separator: separator ?? this.separator,
        accent: accent ?? this.accent,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
      );

  @override
  HigColors lerp(ThemeExtension<HigColors>? other, double t) {
    if (other is! HigColors) return this;
    return HigColors(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      card: Color.lerp(card, other.card, t)!,
      label: Color.lerp(label, other.label, t)!,
      secondaryLabel: Color.lerp(secondaryLabel, other.secondaryLabel, t)!,
      separator: Color.lerp(separator, other.separator, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}
```

- [ ] **Step 2: Переписать `lib/app/theme/app_theme.dart`** (HIG light/dark, Inter, HigColors, NavigationBarTheme):
```dart
import 'package:flutter/material.dart';

import 'app_typography.dart';
import 'hig_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light, HigColors.light);
  static ThemeData get dark => _build(Brightness.dark, HigColors.dark);

  static ThemeData _build(Brightness brightness, HigColors hig) {
    final scheme = ColorScheme.fromSeed(
      seedColor: hig.accent,
      brightness: brightness,
      primary: hig.accent,
      surface: hig.card,
      error: hig.danger,
    );
    final baseText = brightness == Brightness.dark ? hig.label : hig.label;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: hig.pageBackground,
      fontFamily: 'Inter',
      extensions: [hig],
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textTheme: TextTheme(
        displayLarge: AppTypography.display.copyWith(color: hig.label),
        headlineLarge: AppTypography.h1.copyWith(color: hig.label),
        headlineMedium: AppTypography.h2.copyWith(color: hig.label),
        titleMedium: AppTypography.headline.copyWith(color: hig.label),
        bodyLarge: AppTypography.body.copyWith(color: hig.label),
        bodyMedium: AppTypography.subhead.copyWith(color: hig.secondaryLabel),
        bodySmall: AppTypography.footnote.copyWith(color: hig.secondaryLabel),
        labelLarge: AppTypography.button.copyWith(color: hig.accent),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: hig.pageBackground,
        foregroundColor: hig.label,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: hig.card,
        indicatorColor: hig.accent.withValues(alpha: 0.16),
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          AppTypography.caption.copyWith(color: hig.secondaryLabel),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? hig.accent
                  : hig.secondaryLabel,
            )),
      ),
      dividerTheme: DividerThemeData(color: hig.separator, thickness: 0.5, space: 0.5),
      scrollbarTheme: const ScrollbarThemeData(thickness: WidgetStatePropertyAll(0)),
    );
  }
}
```
(`baseText` оставлен для ясности; можно не использовать.)

- [ ] **Step 3: Починить `lib/app/app.dart`** — применить выбранную тему (gating на prefs):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_provider.dart';

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
    );
  }
}
```

- [ ] **Step 4: Анализ.** `cd frontend && flutter analyze lib/app/theme lib/app/app.dart` — 0 ошибок.

- [ ] **Step 5: Commit**
```bash
git add frontend/lib/app/theme/hig_colors.dart frontend/lib/app/theme/app_theme.dart frontend/lib/app/app.dart
git commit -m "feat(hig): HigColors ThemeExtension, HIG light/dark тема, wiring themeMode"
```

---

## Task 3: HIG-компоненты + widget-тесты

**Files:** `inset_section.dart`; `hig_button.dart`; `hig_text_field.dart`; `large_title_scaffold.dart`; test `test/shared/hig_components_test.dart`.

- [ ] **Step 1: `lib/shared/widgets/inset_section.dart`** (`InsetSection` + `InsetTile`):
```dart
import 'package:aifb/app/theme/hig_colors.dart';
import 'package:flutter/material.dart';

/// Сгруппированная inset-секция в стиле iOS grouped list.
class InsetSection extends StatelessWidget {
  const InsetSection({required this.children, this.header, super.key});

  final String? header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(Divider(height: 0.5, thickness: 0.5, indent: 16, color: hig.separator));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              header!.toUpperCase(),
              style: TextStyle(fontSize: 13, color: hig.secondaryLabel, letterSpacing: 0.2),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: hig.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

/// Строка для [InsetSection].
class InsetTile extends StatelessWidget {
  const InsetTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 17, color: hig.label)),
                  if (subtitle != null)
                    Text(subtitle!, style: TextStyle(fontSize: 13, color: hig.secondaryLabel)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null)
              Icon(Icons.chevron_right, color: hig.secondaryLabel, size: 20),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: `lib/shared/widgets/hig_button.dart`:**
```dart
import 'package:aifb/app/theme/hig_colors.dart';
import 'package:flutter/material.dart';

enum HigButtonStyle { filled, tinted, plain }

class HigButton extends StatelessWidget {
  const HigButton({
    required this.label,
    required this.onPressed,
    this.style = HigButtonStyle.filled,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final HigButtonStyle style;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);
    final bg = switch (style) {
      HigButtonStyle.filled => hig.accent,
      HigButtonStyle.tinted => hig.accent.withValues(alpha: 0.15),
      HigButtonStyle.plain => Colors.transparent,
    };
    final fg = style == HigButtonStyle.filled ? Colors.white : hig.accent;
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: loading ? null : onPressed,
          child: Center(
            child: loading
                ? SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                : Text(label,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: fg)),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: `lib/shared/widgets/hig_text_field.dart`:**
```dart
import 'package:aifb/app/theme/hig_colors.dart';
import 'package:flutter/material.dart';

class HigTextField extends StatelessWidget {
  const HigTextField({
    required this.controller,
    this.label,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.errorText,
    super.key,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(fontSize: 17, color: hig.label),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        filled: true,
        fillColor: hig.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: hig.separator),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: hig.accent, width: 1.5),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
```

- [ ] **Step 4: `lib/shared/widgets/large_title_scaffold.dart`:**
```dart
import 'package:aifb/app/theme/hig_colors.dart';
import 'package:flutter/material.dart';

/// Scaffold с крупным сворачивающимся заголовком (HIG large title).
class LargeTitleScaffold extends StatelessWidget {
  const LargeTitleScaffold({
    required this.title,
    required this.slivers,
    this.actions,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final List<Widget> slivers;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);
    return Scaffold(
      backgroundColor: hig.pageBackground,
      floatingActionButton: floatingActionButton,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(title),
            actions: actions,
            backgroundColor: hig.pageBackground,
            surfaceTintColor: Colors.transparent,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(delegate: SliverChildListDelegate(slivers)),
          ),
        ],
      ),
    );
  }
}
```
(NOTE: `slivers` здесь — обычные виджеты внутри `SliverList`; назван так для смысловой ясности «контент под заголовком». Передавайте обычные Column-дети.)

- [ ] **Step 5: Widget-тесты** `frontend/test/shared/hig_components_test.dart`:
```dart
import 'package:aifb/app/theme/app_theme.dart';
import 'package:aifb/shared/widgets/hig_button.dart';
import 'package:aifb/shared/widgets/inset_section.dart';
import 'package:aifb/shared/widgets/large_title_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void main() {
  testWidgets('InsetSection renders header and tiles', (tester) async {
    await tester.pumpWidget(_wrap(Scaffold(
      body: InsetSection(
        header: 'Раздел',
        children: const [InsetTile(title: 'Строка 1'), InsetTile(title: 'Строка 2')],
      ),
    )));
    expect(find.text('РАЗДЕЛ'), findsOneWidget);
    expect(find.text('Строка 1'), findsOneWidget);
    expect(find.text('Строка 2'), findsOneWidget);
  });

  testWidgets('HigButton fires onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(Scaffold(
      body: HigButton(label: 'OK', onPressed: () => tapped = true),
    )));
    await tester.tap(find.text('OK'));
    expect(tapped, isTrue);
  });

  testWidgets('LargeTitleScaffold shows title', (tester) async {
    await tester.pumpWidget(_wrap(const LargeTitleScaffold(
      title: 'Главная',
      slivers: [Text('контент')],
    )));
    expect(find.text('Главная'), findsWidgets);
    expect(find.text('контент'), findsOneWidget);
  });
}
```

- [ ] **Step 6: Run + commit**
```bash
cd frontend && flutter test test/shared/hig_components_test.dart && flutter analyze lib/shared/widgets
git add frontend/lib/shared/widgets/inset_section.dart frontend/lib/shared/widgets/hig_button.dart frontend/lib/shared/widgets/hig_text_field.dart frontend/lib/shared/widgets/large_title_scaffold.dart frontend/test/shared/hig_components_test.dart
git commit -m "feat(hig): компоненты InsetSection/InsetTile/HigButton/HigTextField/LargeTitleScaffold с тестами"
```

---

## Task 4: Навигационная оболочка (таб-бар) + экран «Ещё»

**Files:** `routes.dart` (+more); `app_shell.dart`; `more_page.dart`; `app_router.dart` (StatefulShellRoute); test `test/app/navigation_shell_test.dart`.

- [ ] **Step 1: `routes.dart`** — добавить в App shell: `static const more = _Route('more', '/more');`

- [ ] **Step 2: Оболочка** `lib/app/shell/app_shell.dart`:
```dart
import 'package:aifb/app/theme/hig_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Нижний таб-бар поверх веток StatefulShellRoute.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final hig = HigColors.of(context);
    return Scaffold(
      backgroundColor: hig.pageBackground,
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.swap_vert_outlined), selectedIcon: Icon(Icons.swap_vert_rounded), label: 'Операции'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart_rounded), label: 'Бюджеты'),
          NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag_rounded), label: 'Цели'),
          NavigationDestination(icon: Icon(Icons.more_horiz_outlined), selectedIcon: Icon(Icons.more_horiz_rounded), label: 'Ещё'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Экран «Ещё»** `lib/features/more/presentation/pages/more_page.dart`:
```dart
import 'package:aifb/app/router/routes.dart';
import 'package:aifb/app/theme/theme_mode_provider.dart';
import 'package:aifb/features/auth/presentation/controllers/auth_controller.dart';
import 'package:aifb/features/auth/presentation/state/auth_state.dart';
import 'package:aifb/shared/widgets/inset_section.dart';
import 'package:aifb/shared/widgets/large_title_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final isAdmin = auth is AuthAuthenticated && auth.user.roles.contains('ADMIN');
    final mode = ref.watch(themeModeProvider);
    return LargeTitleScaffold(
      title: 'Ещё',
      slivers: [
        InsetSection(
          header: 'Управление',
          children: [
            InsetTile(title: 'Семья', leading: const Icon(Icons.group_rounded),
                onTap: () => context.push(AppRoutes.family.path)),
            InsetTile(title: 'Группы категорий', leading: const Icon(Icons.folder_rounded),
                onTap: () => context.push(AppRoutes.groups.path)),
            InsetTile(title: 'Правила категоризации', leading: const Icon(Icons.auto_awesome_rounded),
                onTap: () => context.push(AppRoutes.rules.path)),
          ],
        ),
        const SizedBox(height: 24),
        InsetSection(
          header: 'Оформление',
          children: [
            InsetTile(
              title: 'Тема',
              leading: const Icon(Icons.brightness_6_rounded),
              trailing: DropdownButton<ThemeMode>(
                value: mode,
                underline: const SizedBox.shrink(),
                onChanged: (m) {
                  if (m != null) ref.read(themeModeProvider.notifier).set(m);
                },
                items: const [
                  DropdownMenuItem(value: ThemeMode.system, child: Text('Система')),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('Светлая')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Тёмная')),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        InsetSection(
          children: [
            if (isAdmin)
              InsetTile(title: 'Админ-панель', leading: const Icon(Icons.admin_panel_settings_rounded),
                  onTap: () => context.push(AppRoutes.admin.path)),
            InsetTile(
              title: 'Выйти',
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              onTap: () => ref.read(authControllerProvider.notifier).logout(),
            ),
          ],
        ),
      ],
    );
  }
}
```
NOTE: verify `authControllerProvider.notifier` exposes `logout()` (READ `auth_controller.dart`); if the method differs (e.g. `signOut`), adapt and report. If `AuthAuthenticated.user.roles` is a `Set<String>`/`List<String>`, `.contains('ADMIN')` works.

- [ ] **Step 4: Перестроить `app_router.dart` на `StatefulShellRoute`.** Replace the `routes:` list so the 5 tab branches live under a `StatefulShellRoute.indexedStack` wrapped by `AppShell`, and auth/secondary routes stay top-level. Keep the existing `redirect`, `refreshListenable`, `initialLocation`, imports for pages, and add imports for `AppShell` and `MorePage`. The new `routes:` value:
```dart
    routes: [
      GoRoute(path: AppRoutes.login.path, name: AppRoutes.login.name,
          pageBuilder: (ctx, state) => fadeThroughPage(key: state.pageKey, child: const LoginPage())),
      GoRoute(path: AppRoutes.register.path, name: AppRoutes.register.name,
          pageBuilder: (ctx, state) => fadeThroughPage(key: state.pageKey, child: const RegisterPage())),
      // Вторичные экраны — поверх оболочки (push, full-screen с back)
      GoRoute(path: AppRoutes.family.path, name: AppRoutes.family.name,
          pageBuilder: (ctx, state) => fadeThroughPage(key: state.pageKey, child: const FamilyPage())),
      GoRoute(path: AppRoutes.groups.path, name: AppRoutes.groups.name,
          pageBuilder: (ctx, state) => fadeThroughPage(key: state.pageKey, child: const GroupsPage())),
      GoRoute(path: AppRoutes.rules.path, name: AppRoutes.rules.name,
          pageBuilder: (ctx, state) => fadeThroughPage(key: state.pageKey, child: const RulesPage())),
      GoRoute(path: AppRoutes.admin.path, name: AppRoutes.admin.name,
          pageBuilder: (ctx, state) => fadeThroughPage(key: state.pageKey, child: const AdminDatabasePage())),
      StatefulShellRoute.indexedStack(
        builder: (ctx, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.dashboard.path, name: AppRoutes.dashboard.name,
                builder: (ctx, state) => const DashboardPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.transactions.path, name: AppRoutes.transactions.name,
                builder: (ctx, state) => const TransactionsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.budgets.path, name: AppRoutes.budgets.name,
                builder: (ctx, state) => const BudgetsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.goals.path, name: AppRoutes.goals.name,
              builder: (ctx, state) => const GoalsPage(),
              routes: [
                GoRoute(path: ':id',
                    builder: (ctx, state) => GoalDetailPage(goalId: state.pathParameters['id']!)),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.more.path, name: AppRoutes.more.name,
                builder: (ctx, state) => const MorePage()),
          ]),
        ],
      ),
    ],
```
Add imports: `import '../shell/app_shell.dart';` and `import '../../features/more/presentation/pages/more_page.dart';`. Remove now-unused `_Placeholder` and routes for splash/onboarding/analytics/ai/moments/profile/forgot/verify (they were placeholders) — OR keep splash/onboarding if `redirect` references them. The `redirect` references `AppRoutes.splash.path`/`onboarding.path` and `/auth` prefix: keep `isBootstrap` logic working — since we removed splash/onboarding routes, ensure `initialLocation` is `AppRoutes.dashboard.path` (already) and that no route navigates to splash. Keep `forgotPassword`/`verifyEmail`? They were placeholders; safe to drop their routes (login page may link to forgot — verify LoginPage doesn't `context.go` to a now-missing route; if it does, keep a minimal placeholder route). READ `login_page.dart` for any `context.go(AppRoutes.forgotPassword...)`; if present, keep those two `GoRoute`s with the existing `_Placeholder` (then keep `_Placeholder` class too). Report what you kept.

- [ ] **Step 5: Navigation widget test** `frontend/test/app/navigation_shell_test.dart`:
```dart
import 'package:aifb/app/shell/app_shell.dart';
import 'package:aifb/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('AppShell renders NavigationBar with 5 destinations', (tester) async {
    final router = GoRouter(
      initialLocation: '/a',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (ctx, state, shell) => AppShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/a', builder: (c, s) => const Text('A'))]),
            StatefulShellBranch(routes: [GoRoute(path: '/b', builder: (c, s) => const Text('B'))]),
            StatefulShellBranch(routes: [GoRoute(path: '/c', builder: (c, s) => const Text('C'))]),
            StatefulShellBranch(routes: [GoRoute(path: '/d', builder: (c, s) => const Text('D'))]),
            StatefulShellBranch(routes: [GoRoute(path: '/e', builder: (c, s) => const Text('E'))]),
          ],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(theme: AppTheme.light, routerConfig: router));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Главная'), findsOneWidget);
    expect(find.text('Ещё'), findsOneWidget);
  });
}
```

- [ ] **Step 6: Анализ + полный прогон + сборка**
```bash
cd frontend && flutter analyze lib && flutter test && flutter build web --no-tree-shake-icons
```
Expected: analyze 0 errors/warnings (info ок), все тесты passed, `✓ Built build/web`. (Сборка ловит регрессии вёрстки.)

- [ ] **Step 7: Commit**
```bash
git add frontend/lib/app/router/routes.dart frontend/lib/app/shell frontend/lib/features/more frontend/lib/app/router/app_router.dart frontend/test/app/navigation_shell_test.dart
git commit -m "feat(hig): навигационная оболочка (таб-бар, 5 вкладок) + экран «Ещё»"
```

---

## Self-review (выполнено при написании плана)

- **Покрытие спеки (фундамент):** Inter (Task 1), HIG-палитра light/dark через `HigColors` + тема (Task 2), компоненты `InsetSection/InsetTile/HigButton/HigTextField/LargeTitleScaffold` (Task 3), нижний таб-бар (5 вкладок) + «Ещё»-хаб (Task 4), починка `themeMode` (Task 2). Поэкранная переработка вёрстки — План 2.
- **Плейсхолдеры:** нет — полный код либо точечные правки с местом; единственные «прочитай и адаптируй» помечены явно (имя метода logout, маршруты forgot/verify — с инструкцией что проверить/сохранить).
- **Согласованность типов:** `HigColors.of(context)` и поля (`pageBackground/card/label/secondaryLabel/separator/accent/...`) используются единообразно во всех компонентах и оболочке. `AppTypography` имена сохранены (старые экраны компилируются). `StatefulNavigationShell`/`StatefulShellRoute.indexedStack` — go_router API (версия 14.x в pubspec).
- **Риск-снижение:** значения `AppColors` перекрашены при сохранении имён → старые экраны компилируются и сразу выглядят ближе к HIG; полноценная адаптация вёрстки/тёмной темы по экранам — План 2. `glassWhite/glassBorder` удалены (единственный потребитель — `glass_card.dart`, мигрируется в Плане 2); Step 5 Task 1 страхует откатом-заглушкой при неожиданных использованиях.
- **Заметка:** `StatefulShellRoute` — крупнейшее изменение; `flutter build web` в Task 4 служит интеграционной проверкой.
