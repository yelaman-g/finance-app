# План 2 — HIG-редизайн: поэкранная переработка

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Перевести все экраны на HIG-вид с использованием компонентов из Плана 1 (LargeTitleScaffold, InsetSection/InsetTile, HigButton, HigTextField, HigColors), убрать градиенты/glass, удалить legacy-виджеты.

**Architecture:** Чисто визуальный слой. Каждый экран: `LargeTitleScaffold` с крупным заголовком, контент — `InsetSection`/`InsetTile` (grouped-списки), действия — `HigButton`, поля — `HigTextField`, цвета — через `HigColors.of(context)` (brightness-aware → корректная тёмная тема). Логика/провайдеры/навигация не меняются (роутер-оболочка уже из Плана 1).

**Tech Stack:** Flutter 3.44, Material 3, Riverpod, `very_good_analysis`.

**Предусловие:** План 1 (фундамент) реализован: компоненты в `lib/shared/widgets/`, `HigColors` в `lib/app/theme/hig_colors.dart`, навигационная оболочка с вкладками. Ветка `feature/hig-redesign`.

**Общий приём для каждого экрана (важно):** субагент СНАЧАЛА читает текущий файл экрана, затем переносит существующую загрузку данных/провайдеры в новый HIG-каркас (заголовок + `InsetSection`). Провайдеры, параметры (`Scope` и т.п.), обработчики не меняются — меняется только представление. После каждого экрана: `flutter analyze <dir>` без новых ошибок.

Команды — из `frontend/`. Гейт каждой задачи: `flutter analyze` без ошибок/warnings (info ок). Финальный гейт: `flutter test` + `flutter build web`.

---

## Task 1: Экраны входа/регистрации (auth)

**Files:** `lib/features/auth/presentation/pages/login_page.dart`, `register_page.dart`.

- [ ] **Step 1: READ** оба файла.
- [ ] **Step 2: Переработать login_page** — убрать `gradient_background`/glass; центрированная форма на `HigColors.of(context).pageBackground`:
  каркас:
```dart
// внутри build (ConsumerWidget/State — сохранить существующий тип и логику контроллеров)
final hig = HigColors.of(context);
return Scaffold(
  backgroundColor: hig.pageBackground,
  body: SafeArea(
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('AIFB', style: Theme.of(context).textTheme.displayLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Вход', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            // HigTextField для email/пароля (перенести существующие controllers/валидацию/ошибки)
            // HigButton(filled) — submit (перенести существующий onPressed/loading/error)
          ],
        ),
      ),
    ),
  ),
);
```
  Импорты: `package:aifb/app/theme/hig_colors.dart`, `package:aifb/shared/widgets/hig_text_field.dart`, `package:aifb/shared/widgets/hig_button.dart`. Сохранить всю существующую логику отправки/валидации/состояния и переходы (`context.go`/`push`).
- [ ] **Step 3: Переработать register_page** аналогично (поля имя/email/пароль через `HigTextField`, submit — `HigButton(filled)`), убрать gradient/glass.
- [ ] **Step 4:** `cd frontend && flutter analyze lib/features/auth` — без новых ошибок. Если login/register ссылались на `primary_button`/`premium_text_field`/`gradient_background` — заменить на HIG-аналоги (эти legacy-виджеты удаляются в Task 6).
- [ ] **Step 5: Commit**
```bash
git add frontend/lib/features/auth/presentation/pages
git commit -m "feat(hig): экраны входа и регистрации в стиле HIG"
```

---

## Task 2: Дашборд (Главная)

**Files:** `lib/features/dashboard/presentation/pages/dashboard_page.dart` + виджеты `widgets/` (balance_card, spending_chart_card, recent_transactions, goal_progress_card, и т.д.).

- [ ] **Step 1: READ** `dashboard_page.dart` и используемые виджеты (особенно `balance_card.dart` — он на `app_gradients`).
- [ ] **Step 2: Заголовок и каркас.** Перевести `DashboardPage` (сохранить `ConsumerStatefulWidget` + `_scope`-стейт и все провайдеры) на `LargeTitleScaffold(title: 'Главная', slivers: [...])`. Удалить `gradient_background`/`_TopBar`/`_IconBubble` (навигация теперь в таб-баре; admin/семья — во вкладке «Ещё»). Сегмент «Личное | Семья» — `SegmentedButton<Scope>` первым элементом.
- [ ] **Step 3: Баланс без градиента.** Заменить `BalanceCard` на плоскую `InsetSection` (или переписать `balance_card.dart` на `HigColors.card`-поверхность без `AppGradients`): крупная сумма `net` (textTheme.displayLarge), под ней доход/расход (`success`/`danger` из HigColors). Убрать импорт/использование `app_gradients`/`AppGradients`.
- [ ] **Step 4: Секции.** «График трат» — на `HigColors.card`-контейнере (fl_chart оставить, фон/линии — accent). «Последние операции», «Цели», «Разбивка по участникам» (в family scope) — через `InsetSection`/`InsetTile`. Сохранить переходы (push на `/transactions`, `/goals` через таб — заменить кнопки на `InsetTile`-«Все» или убрать, т.к. есть вкладки).
- [ ] **Step 5:** `cd frontend && flutter analyze lib/features/dashboard` — без новых ошибок.
- [ ] **Step 6: Commit**
```bash
git add frontend/lib/features/dashboard
git commit -m "feat(hig): дашборд в стиле HIG (large title, inset-секции, без градиентов)"
```

---

## Task 3: Операции + форма

**Files:** `lib/features/transactions/presentation/pages/transactions_page.dart`, `widgets/transaction_form_sheet.dart`.

- [ ] **Step 1: READ** оба.
- [ ] **Step 2: transactions_page** → `LargeTitleScaffold(title: 'Операции')`; список операций — `InsetSection` со строками `InsetTile` (заголовок = категория, подзаголовок = дата+заметка, trailing = сумма цветом по типу через `HigColors.success/danger`/label). Сохранить `Dismissible` swipe-to-delete и `transactionsProvider(Scope.personal)`. Кнопка добавления — `actions: [IconButton(Icons.add)]` в large app bar (вместо FAB) или `floatingActionButton` у `LargeTitleScaffold`.
- [ ] **Step 3: transaction_form_sheet** — поля на `HigTextField`, кнопка «Сохранить» — `HigButton(filled, loading: _saving)`, сегменты тип/«Семейная»/тумблеры сохранить (`SegmentedButton`/`SwitchListTile`), кнопка-подсказка ✨ сохранить. Убрать любые glass/gradient.
- [ ] **Step 4:** `flutter analyze lib/features/transactions` — без новых ошибок.
- [ ] **Step 5: Commit**
```bash
git add frontend/lib/features/transactions
git commit -m "feat(hig): экран операций и форма в стиле HIG"
```

---

## Task 4: Бюджеты, Цели, детали цели

**Files:** `lib/features/budgets/presentation/pages/budgets_page.dart`, `lib/features/goals/presentation/pages/goals_page.dart`, `goal_detail_page.dart`, `lib/features/goals/presentation/widgets/goal_form_sheet.dart`.

- [ ] **Step 1: READ** все четыре.
- [ ] **Step 2: budgets_page** → `LargeTitleScaffold(title: 'Бюджеты')`; лимиты — `InsetSection`, каждая строка: имя цели + `spent/amount` + `LinearProgressIndicator` цветом по статусу (`HigColors.success/warning/danger`), кнопка удаления. Сохранить `budgetsProvider(Scope.personal)`.
- [ ] **Step 3: goals_page** → `LargeTitleScaffold(title: 'Цели')`; цели — `InsetSection`/`InsetTile` с прогрессом; tap → `context.push('${AppRoutes.goals.path}/${g.id}')` (внутри ветки таба). FAB/действие «Новая цель» через `HigButton`/app bar action + `showGoalForm`.
- [ ] **Step 4: goal_detail_page** → `LargeTitleScaffold(title: 'Цель')`; взносы — `InsetSection`; «Пополнить» — `HigButton`/action. `goal_form_sheet` — `HigTextField`/`HigButton`, тумблер «Семейная» сохранить.
- [ ] **Step 5:** `flutter analyze lib/features/budgets lib/features/goals` — без новых ошибок.
- [ ] **Step 6: Commit**
```bash
git add frontend/lib/features/budgets frontend/lib/features/goals
git commit -m "feat(hig): бюджеты, цели и детали цели в стиле HIG"
```

---

## Task 5: Семья, Группы, Правила

**Files:** `lib/features/household/presentation/pages/family_page.dart`, `lib/features/groups/presentation/pages/groups_page.dart`, `lib/features/categorization/presentation/pages/rules_page.dart`.

- [ ] **Step 1: READ** все три.
- [ ] **Step 2: family_page** → `LargeTitleScaffold(title: 'Семья')`. Нет семьи: `InsetSection` с `HigTextField` (название/код) + `HigButton` (Создать/Вступить). Есть семья: `InsetSection` «Код приглашения» (с кнопкой обновить), `InsetSection` «Участники» (`InsetTile` + меню ролей), `InsetSection` «Кто сколько потратил». Кнопки выхода/роспуска — `HigButton(plain/filled)` с `danger`-цветом. Сохранить все провайдеры/репозиторий-вызовы.
- [ ] **Step 3: groups_page** → `LargeTitleScaffold(title: 'Группы')`; список — `InsetSection`/`InsetTile` (имя + тип, удаление trailing). Диалог создания — поля/кнопки в HIG-стиле (можно оставить `AlertDialog`, кнопки — `HigButton`/Text). Сохранить `groupsProvider(Scope.personal)`.
- [ ] **Step 4: rules_page** → `LargeTitleScaffold(title: 'Правила')`; список — `InsetSection`/`InsetTile` («keyword → категория», удаление). Диалог создания сохранить логически, стиль — HIG. Сохранить `rulesProvider`.
- [ ] **Step 5:** `flutter analyze lib/features/household lib/features/groups lib/features/categorization` — без новых ошибок.
- [ ] **Step 6: Commit**
```bash
git add frontend/lib/features/household frontend/lib/features/groups frontend/lib/features/categorization
git commit -m "feat(hig): семья, группы и правила в стиле HIG"
```

---

## Task 6: Admin-рестайл, удаление legacy-виджетов, финальная проверка

**Files:** `lib/features/admin/presentation/pages/admin_database_page.dart`; удаление `lib/shared/widgets/{glass_card,gradient_background,premium_text_field,primary_button}.dart`, `lib/app/theme/app_gradients.dart`; возможные оставшиеся импорты.

- [ ] **Step 1: admin** — READ `admin_database_page.dart`; перевести фон на `HigColors.pageBackground`, поверхности результатов на `HigColors.card`, текст — Inter/textTheme, кнопки — `HigButton`/`FilledButton` (тема). Глубокую перекройку таблицы не делать — только единый стиль.
- [ ] **Step 2: Найти оставшиеся использования legacy-виджетов:**
```bash
cd frontend && grep -rn "GlassCard\|GradientBackground\|PremiumTextField\|PrimaryButton\|AppGradients\|app_gradients\|glass_card\|gradient_background\|premium_text_field\|primary_button" lib || echo "нет использований"
```
- [ ] **Step 3:** Заменить все оставшиеся использования на HIG-аналоги (`HigColors`/`HigButton`/`HigTextField`/`InsetSection`). Повторять Step 2, пока «нет использований».
- [ ] **Step 4: Удалить legacy-файлы:**
```bash
cd frontend && rm -f lib/shared/widgets/glass_card.dart lib/shared/widgets/gradient_background.dart lib/shared/widgets/premium_text_field.dart lib/shared/widgets/primary_button.dart lib/app/theme/app_gradients.dart
```
- [ ] **Step 5: Полная проверка:**
```bash
cd frontend && flutter analyze lib && flutter test && flutter build web --no-tree-shake-icons
```
Expected: analyze 0 errors/warnings (info ок); все тесты passed; `✓ Built build/web`. Если `app_colors.dart` всё ещё содержит `glassWhite/glassBorder`-заглушки и они больше не используются — удалить их.
- [ ] **Step 6: Commit**
```bash
git add -A frontend/lib
git commit -m "feat(hig): admin-рестайл, удаление legacy-виджетов, финальная HIG-чистка"
```

---

## Task 7: Ручная визуальная проверка (light + dark)

- [ ] **Step 1: Поднять стек и пройти все экраны.**
```bash
docker start aifb-db 2>/dev/null || true
( cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew bootRun & )
cd frontend && flutter run -d chrome --web-port 3000
```
Проверить вручную: таб-бар (5 вкладок) работает; large titles сворачиваются при скролле; нет градиентов/glass; переключатель темы в «Ещё» меняет light/dark и весь UI остаётся читаемым (HigColors); экраны Семья/Группы/Правила/Админ открываются из «Ещё»; формы (операция/цель/бюджет/правило) в HIG-стиле.

---

## Self-review (выполнено при написании плана)

- **Покрытие спеки:** все экраны (auth, дашборд, операции+форма, бюджеты, цели+детали, семья, группы, правила, admin) переведены на HIG-компоненты; удаление градиентов/glass и legacy-виджетов (Task 6); ручная проверка light/dark (Task 7). Соответствует разделу «Поэкранная переработка» спеки.
- **Плейсхолдеры:** задачи UI-рестайла намеренно в форме «READ текущий экран → применить HIG-каркас (конкретные компоненты/код-скелет) → проверить analyze/build», т.к. это перенос существующей data-логики в новое представление; приведены конкретные компоненты и каркасы, целевая структура каждого экрана и команды-гейты. Это не «доделать сами» — указано чем заменить и как проверить.
- **Согласованность:** используются ровно те компоненты/типы, что созданы в Плане 1 (`LargeTitleScaffold(title, slivers, actions, floatingActionButton)`, `InsetSection(header, children)`, `InsetTile(title, subtitle, leading, trailing, onTap)`, `HigButton(label, onPressed, style, loading)`, `HigTextField(controller, label, hint, keyboardType, obscureText, errorText)`, `HigColors.of(context)`); провайдеры/маршруты/логика не меняются.
- **Порядок:** legacy-виджеты удаляются ТОЛЬКО в Task 6 (после миграции всех экранов в Tasks 1–5) — иначе сломается сборка. Финальный `flutter build web` ловит регрессии вёрстки.
