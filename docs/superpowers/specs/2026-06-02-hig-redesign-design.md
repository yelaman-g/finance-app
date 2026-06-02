# Редизайн под Apple HIG — дизайн

Дата: 2026-06-02
Статус: согласован, готов к планированию реализации

## Контекст

AIFB — дипломный проект (Flutter Web + Spring Boot). Реализован весь функционал
(ядро+цели, семейный бюджет, группы, лимиты, авто-категоризация). Текущий визуальный язык —
кастомный «премиум-градиентный»: синие градиенты, glass-карточки, `gradient_background`,
кастомные `glass_card`/`premium_text_field`/`primary_button`, дизайн-система в `lib/app/theme/`
(`app_colors`, `app_gradients`, `app_typography`, `app_spacing`, `app_theme`, `theme_mode_provider`),
светлая+тёмная темы. Навигация — push-переходы (go_router), постоянного таб-бара нет.
Экраны: login, register, dashboard, transactions, goals (+detail), family, groups, budgets, rules, admin.

Цель — привести весь интерфейс к единому современному стилю **по принципам Apple HIG**
(clarity, deference, depth): чисто, плоско, системные цвета, крупные заголовки, сгруппированные
inset-списки, нижний таб-бар. Это одна сквозная подсистема (единый визуальный язык).

Зависит от ветки `feature/auto-categorization` (последняя — включает все экраны).

## Согласованные решения

- **Направление (A):** HIG-вдохновлённая система на **Material**-виджетах (не Cupertino) — кроссплатформенно
  для Web, без переписывания на другую библиотеку.
- **Охват (A):** полный — новые токены + общие компоненты + ручная переработка вёрстки **всех ~10 экранов**.
- **Фирменные элементы (A):** чистый HIG-флэт — **убираем градиенты и glass полностью**; системные плоские
  поверхности, крупные заголовки (large title), inset-grouped списки с hairline-разделителями,
  один акцент (системный синий), семантические success/warning/danger.
- **Акцент:** системный синий `#007AFF` (light) / `#0A84FF` (dark). **Тёмная тема сохраняется** (HIG-палитра для обеих).
- **Типографика:** шрифт **Inter** (SF нельзя встраивать по лицензии; Inter — близкий бесплатный аналог), встраивается в проект.
- **Навигация:** нижний `NavigationBar`, 5 вкладок: Главная · Операции · Бюджеты · Цели · Ещё;
  «Ещё» — хаб (Семья, Группы, Правила, Тема, Профиль/Выход, Админ при роли ADMIN).

## Дизайн-токены

### Цвета (`app_colors.dart` переписывается; `app_gradients.dart` удаляется)
**Light:** page bg `#F2F2F7`; section/card `#FFFFFF`; label `#000000`; secondaryLabel `#3C3C43`@60%;
tertiaryLabel `#3C3C43`@30%; separator `#C6C6C8`; accent `#007AFF`; success `#34C759`; warning `#FF9F0A`; danger `#FF3B30`.
**Dark:** page bg `#000000`; section/card `#1C1C1E`; elevated `#2C2C2E`; label `#FFFFFF`; secondaryLabel `#EBEBF5`@60%;
separator `#38383A`; accent `#0A84FF`; success `#30D158`; warning `#FF9F0A`; danger `#FF453A`.

### Типографика (`app_typography.dart`, шрифт Inter)
largeTitle 34/w700 · title1 28/w700 · title2 22/w700 · title3 20/w600 · headline 17/w600 · body 17/w400 ·
callout 16/w400 · subhead 15/w400 · footnote 13/w400 · caption 12/w400. Цвет по умолчанию — label.

### Spacing / форма (`app_spacing.dart`)
8-pt grid: xs 4 · sm 8 · md 12 · lg 16 · xl 20 · xxl 24 · xxxl 32. Радиусы: control 10 · card/section 12 · pill 999.
Плоско: секции — фон `card` + опциональная очень мягкая тень/без тени; разделители — hairline 0.5–1px `separator`.

### Шрифт Inter
- Добавить `assets/fonts/Inter-*.ttf` (Regular/Medium/SemiBold/Bold) и объявить `fonts:` в `pubspec.yaml`.
- В `app_theme.dart` задать `fontFamily: 'Inter'` для light/dark `ThemeData` (Material 3, `useMaterial3: true`).

## Общие компоненты (`lib/shared/widgets/`)

Удаляются/перестают использоваться: `glass_card.dart`, `gradient_background.dart`, `premium_text_field.dart`,
`primary_button.dart` (после миграции всех использований — удалить файлы).

Создаются:
- **`InsetSection`** — сгруппированная inset-секция: опциональный заголовок-капс (footnote/secondaryLabel),
  скруглённый (12) контейнер `card`, дочерние строки через hairline-разделители (как iOS grouped list).
- **`InsetTile`** — строка для `InsetSection` (заголовок, опц. подзаголовок/leading/trailing/`onTap` + chevron).
- **`HigButton`** — варианты `filled` (фон accent, белый текст), `tinted` (accent@15%, текст accent),
  `plain` (текст accent); высота 50, радиус 12, headline-шрифт.
- **`HigTextField`** — чистое поле: `card`-фон, радиус 10, без тяжёлых рамок; ошибка — danger.
- **`LargeTitleScaffold`** — `Scaffold` + `CustomScrollView` со `SliverAppBar.large` (крупный заголовок,
  сворачивается при скролле; фон страницы `page bg`), слот для действий и контента (sliver/list).

## Навигация (`lib/app/router/`)

- Ввести `StatefulShellRoute.indexedStack` с 5 ветками и нижним `NavigationBar` (Material 3, флэт, accent-индикатор):
  **Главная** (`/dashboard`) · **Операции** (`/transactions`) · **Бюджеты** (`/budgets`) · **Цели** (`/goals`) · **Ещё** (`/more`).
- Каждая корневая вкладка — экран на `LargeTitleScaffold`. Вторичные (`/goals/:id` детали, формы-боттомшиты) — push поверх оболочки.
- Новый экран **«Ещё»** (`/more`): `InsetSection`-список → Семья (`/family`), Группы (`/groups`), Правила (`/rules`),
  переключатель темы (light/dark/system через `theme_mode_provider`), Профиль/Выход, и Админ (`/admin`) при роли ADMIN.
- Редирект-логика auth (`appRouterProvider`) сохраняется; shell — только для аутентифицированной зоны.
- Старые точки входа (иконки в топ-баре дашборда: admin/notifications, кнопки «Manage» и т.п.) заменяются вкладками/«Ещё».

## Поэкранная переработка (все экраны)

- **login / register:** `LargeTitleScaffold` или центрированная форма на `page bg`; `HigTextField` + `HigButton(filled)`;
  убрать `gradient_background`/`glass`.
- **dashboard (Главная):** large title «Главная»; баланс — плоская `InsetSection`-карточка (доход/расход/нетто
  числами, без градиента); график трат (`fl_chart`) на `card`-поверхности; «последние операции» и «цели» — `InsetSection`;
  переключатель «Личное | Семья» — `SegmentedButton` в HIG-стиле; карточка разбивки по участникам (в семейном scope).
- **transactions (Операции):** large title; список — `InsetSection`/`InsetTile` (категория, дата, сумма с цветом по типу),
  swipe-to-delete сохраняется; FAB → HIG-кнопка/`+` в app bar; форма — боттомшит с `HigTextField`/`HigButton`,
  сегмент тип, тумблер «Семейная», кнопка-подсказка ✨.
- **budgets (Бюджеты):** large title; список лимитов — `InsetSection` с прогресс-полосой (цвет по статусу
  OK/WARNING/EXCEEDED через семантические цвета); удаление.
- **goals (Цели) + detail:** large title; цели — `InsetSection` с прогрессом; детали — список взносов `InsetSection`,
  «Пополнить» — `HigButton`.
- **family:** large title; участники/код/разбивка — `InsetSection`; роли — через `InsetTile` + меню;
  формы создать/вступить — `HigTextField`/`HigButton`.
- **groups / rules:** large title; списки — `InsetSection`/`InsetTile`; создание — диалог/боттомшит в HIG-стиле.
- **admin:** перевести на `page bg`/`card`-поверхности и Inter; таблица результатов в `card`-контейнере;
  глубокую перекройку таблицы не делаем (функциональный экран), но единый стиль (фон/типографика/кнопки) применяем.

## Тёмная тема

- `app_theme.dart`: два `ThemeData` (light/dark) на Material 3 с HIG-палитрой и `fontFamily: 'Inter'`;
  `ColorScheme` собирается из токенов (primary=accent, surface=card, background=page bg, error=danger и т.д.).
- `theme_mode_provider` сохраняется; в «Ещё» — переключатель light/dark/system.

## Тестирование

Визуальный вид юнит-тестами не проверяется напрямую. Подход:
- **Widget-тесты (flutter_test)** на новые компоненты: `InsetSection`/`InsetTile` (рендер заголовка, строк, разделителей,
  `onTap`), `HigButton` (варианты, `onPressed`), `HigTextField` (ввод, ошибка), `LargeTitleScaffold` (заголовок присутствует).
- **Навигация:** widget-тест, что `StatefulShellRoute` рендерит `NavigationBar` с 5 вкладками и переключает ветки.
- **`flutter analyze`** — 0 ошибок/warnings (info-хинты допустимы).
- **Существующие тесты** (репозитории, smoke) остаются зелёными.
- **Ручной прогон** в Chrome: пройти все экраны в light и dark, проверить отсутствие градиентов/glass и единый стиль.

## Вне объёма (фиксируем явно)

- Cupertino-виджеты (остаёмся на Material).
- Анимации/переходы сверх существующих `flutter_animate`/`fadeThroughPage` (можно упомянуть в «развитии»).
- Изменение функциональности/логики экранов — только визуальный слой и навигационная оболочка.
- Глубокая перекройка экрана `admin` (только единый стиль поверхностей/типографики).
- Брендовые иллюстрации/иконки сверх Material Icons.

## Известные технические заметки

- Бэкенд и API не затрагиваются — чисто фронтовый редизайн.
- Удаление `app_gradients.dart`/`glass_card`/`gradient_background`/`premium_text_field`/`primary_button`
  выполняется только после миграции всех использований (иначе сломается сборка).
- Inter добавляется как ассет-шрифт; SF не используется (лицензия).
- Material 3 `SliverAppBar.large` даёт крупный сворачивающийся заголовок без Cupertino.
- Нижний таб-бар требует перевода роутера на `StatefulShellRoute.indexedStack` — крупнейшее структурное изменение редизайна.
