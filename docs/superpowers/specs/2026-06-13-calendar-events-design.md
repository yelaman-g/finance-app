# Семейный календарь / события (ТЗ этап 7) — design

Дата: 2026-06-13
Статус: согласован
Подсистема: семейный календарь (этап 7 ТЗ). Средний приоритет, подсистема 1 из 2
(вторая — FCM push, отдельный цикл).

## 1. Цель и контекст

Общие семейные события: дни рождения, встречи, школьное расписание. События
видны всем членам семьи (семейный скоуп) или личные. Поддерживаются повторения
(ежедневно/еженедельно/ежемесячно/ежегодно). Месячная сетка-календарь на фронте.
Разовое событие с бюджетом интегрируется с уже готовым модулем `ai_reminders`
(AI отслеживает накопления к дате; FCM-доставка — следующий этап).

Модуля событий нет (greenfield). Календарной зависимости во фронте нет.

## 2. Границы (scope)

**Входит:**
- Backend-модуль `event`: сущность + миграция V16 `events`, CRUD-эндпоинты
  `/api/v1/events`, раскрытие повторений на сервере, интеграция с `ai_reminders`.
- Frontend-фича `calendar`: месячная сетка (`table_calendar`), список событий дня,
  форма создания/редактирования, маршрут `/calendar` + вход из «Ещё».
- Тесты backend (раскрытие повторений, CRUD, scope, AI-связь) и frontend.

**Не входит:**
- **Правка/отмена отдельного вхождения серии** (RRULE EXDATE/override) —
  редактирование и удаление работают на серии целиком. Это «кроличья нора»
  recurrence; отдельная задача позже.
- **Push о событиях** — относится к подсистеме FCM (этап 5, следующий цикл).
- **Правка события из UI (PUT)** — эндпоинт `PUT /events/{id}` реализован и
  протестирован на бэкенде, но во фронте тап по событию ведёт к
  подтверждению/удалению серии; форма правки в UI отложена (создание + удаление +
  просмотр — ядро MVP).
- **Ре-синк связанного `ai_reminder` при правке события** — напоминание
  создаётся при создании события и удаляется при удалении; правка события не
  обновляет напоминание (документированное ограничение MVP).

## 3. Модель данных — миграция V16 `events`

Конвенции проекта (UUID + household-scope + version, как `goals`/`ai_reminders`):

```sql
CREATE TABLE events (
    id              UUID PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    household_id    UUID REFERENCES households(id) ON DELETE CASCADE,  -- NULL = личное
    title           VARCHAR(200) NOT NULL,
    description     VARCHAR(2000),
    start_date      DATE NOT NULL,
    start_time      TIME,                 -- NULL при all_day
    all_day         BOOLEAN NOT NULL DEFAULT TRUE,
    type            VARCHAR(16) NOT NULL DEFAULT 'OTHER',  -- BIRTHDAY|MEETING|SCHOOL|OTHER
    recur_freq      VARCHAR(8) NOT NULL DEFAULT 'NONE',    -- NONE|DAILY|WEEKLY|MONTHLY|YEARLY
    recur_interval  INTEGER NOT NULL DEFAULT 1,
    recur_until     DATE,                 -- NULL = бесконечно (раскрываем только в запрошенный диапазон)
    ai_reminder_id  UUID REFERENCES ai_reminders(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    version         BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_events_user ON events (user_id);
CREATE INDEX idx_events_household ON events (household_id);
```

Сущность `Event extends BaseEntity`; enum'ы `EventType {BIRTHDAY,MEETING,SCHOOL,OTHER}`,
`RecurFreq {NONE,DAILY,WEEKLY,MONTHLY,YEARLY}` (`@Enumerated(STRING)`).
`ai_reminder_id` — мягкая ссылка на `ai_reminders` (`ON DELETE SET NULL`, чтобы
удаление напоминания из AI-вкладки не ломало событие).

## 4. Повторения (recurrence) — раскрытие на сервере

Отдельный компонент `RecurrenceExpander` (чистая логика, тестируемая изолированно):
`List<LocalDate> occurrences(Event e, LocalDate from, LocalDate to)`:
- `NONE`: `[start_date]` если попадает в `[from,to]`, иначе пусто.
- `DAILY`: `start_date, +interval дн., …`; `WEEKLY`: `+7·interval дн.`;
  `MONTHLY`: `start_date.plusMonths(interval·k)`; `YEARLY`: `plusYears(interval·k)`.
- Предел верхней границы — `min(recur_until, to)`; начинаем с первого вхождения
  `≥ from` (перешагиваем «хвост» до `from`); останавливаемся на `to`.
- **Защитный лимит**: ≤ 400 вхождений на событие за один запрос (страховка от
  раскрутки, напр. ежедневного за годы); при достижении — обрезаем (запрашиваемые
  диапазоны — месяц-два, так что лимит не достигается в норме).

`EventService.list` собирает события (личные/семейные по scope), раскрывает каждое
через `RecurrenceExpander` в `[from,to]`, возвращает плоский список вхождений,
отсортированный по дате/времени.

## 5. Связь с AI-напоминаниями

- **Только разовое событие (`recur_freq=NONE`) с заданным бюджетом** создаёт
  связанный `ai_reminder`: `EventService.create` вызывает `ReminderService.create`
  (имя=title, дата=start_date, target=budget, notifyDaysBefore, shared) и сохраняет
  `event.ai_reminder_id`.
- Если бюджет задан при `recur_freq != NONE` → `VALIDATION_FAILED` (явный отказ, не
  тихий сброс; на фронте поле бюджета скрыто для повторяющихся).
- `EventService.delete`: если `ai_reminder_id != null` — удаляет связанное
  напоминание через `ReminderService.delete`.
- `EventService` зависит от `ReminderService` (направление events → ai; без циклов).

## 6. Backend — эндпоинты `/api/v1/events` (под JWT, `@CurrentUser`)

| Метод | Путь | Тело/параметры | Ответ |
|---|---|---|---|
| GET | `/events` | `?from=&to=&scope=` (даты обязательны для диапазона; scope=PERSONAL\|FAMILY, дефолт PERSONAL) | `List<EventOccurrenceResponse>` |
| POST | `/events` | `CreateEventRequest` | `EventResponse` |
| PUT | `/events/{id}` | `UpdateEventRequest` | `EventResponse` |
| DELETE | `/events/{id}` | — | `ok` |

- `CreateEventRequest{ @NotBlank title, description?, @NotNull startDate, startTime?,
  allDay(bool), type(EventType=OTHER), recurFreq(RecurFreq=NONE), recurInterval(int=1),
  recurUntil?, budget? (BigDecimal — только для NONE), notifyDaysBefore? (List<Integer>),
  shared(bool) }`.
- `UpdateEventRequest{ title, description?, startDate, startTime?, allDay, type,
  recurFreq, recurInterval, recurUntil? }` (без budget — правка серии не трогает
  связанное напоминание; см. §2).
- `EventResponse{ id, title, description?, startDate, startTime?, allDay, type,
  recurFreq, recurInterval, recurUntil?, shared, aiReminderId? }` (одна запись-серия).
- `EventOccurrenceResponse{ eventId, title, description?, date, time?, allDay, type,
  recurring(bool) }` (раскрытое вхождение; `recurring` = recurFreq≠NONE).
- `EventService`: CRUD + scope (как `GoalService`: личное по userId, семейное по
  household + `requireManageSharedContent` для записи) + раскрытие на `list` +
  создание/удаление связанного reminder. `EventRepository` (Spring Data JPA).
- `ErrorCode` уже имеет `VALIDATION_FAILED`/`NOT_FOUND`/`FORBIDDEN` — новых кодов не
  нужно.

## 7. Frontend — фича `calendar`

- Зависимость `table_calendar: ^3.1.2`.
- `lib/features/calendar/`: data (DTO plain-классы `EventOccurrence`, `EventDetail`;
  datasource на `/events` через аутентифицированный `dioProvider`; repository),
  presentation (провайдер событий месяца, экран, форма).
- **Экран** (`CalendarPage`): `TableCalendar` (месячная сетка) с `eventLoader`,
  маркеры на днях с событиями; под сеткой — список событий выбранного дня (название,
  время/«весь день», тип-иконка); FAB → форма создания. Тап по событию →
  диалог подтверждения и удаление серии (для повторяющихся — явно «вся серия»).
- При смене видимого месяца — перезапрос `GET /events?from=<начало месяца−нед.>&to=<конец+нед.>`
  (буфер для краёв сетки); данные кэшируются провайдером по диапазону.
- **Форма** (bottom sheet или страница): название, описание, дата (date picker),
  «весь день» + время (если выключено), тип (dropdown), повтор (freq dropdown +
  interval + опц. until); переключатель «Семейное событие» (`shared`); поле
  «бюджет» + «уведомлять за дн.» — **только при freq=NONE**. Удаление — серией.
- Маршрут `/calendar` (top-level GoRoute, как `/ai`) + пункт `InsetTile`
  «Календарь» в «Ещё» (`more_page.dart`), иконка `Icons.event_rounded`.

## 8. Тестирование (TDD)

- **Backend** (MockMvc + Testcontainers):
  - `RecurrenceExpanderTest` (юнит) — ключевая логика: weekly/monthly/yearly/daily
    раскрытие в диапазон, начало `≥from`, граница `until`, defensive cap, NONE вне
    диапазона → пусто.
  - `EventApiIT`: CRUD; раскрытие (создать weekly → `GET` за месяц возвращает N
    вхождений); scope личное/семейное; разовое+бюджет → создаёт `ai_reminder`,
    удаление события удаляет напоминание; recurring+бюджет → 400 `VALIDATION_FAILED`;
    auth required.
- **Frontend** (flutter_test + mocktail): repo-тесты (datasource→DTO; create body
  c recurrence/budget); виджет-тест `CalendarPage` (рендер сетки + список выбранного
  дня) с замоканным репозиторием.

## 9. Рассмотренные альтернативы

- **Recurrence хранение/раскрытие:** (A) правило на событии + раскрытие на сервере в
  диапазон — *выбрано* (фронт прост, нет хранения тысяч вхождений); (B) материализация
  вхождений в таблицу — отклонено (раздувание, сложная правка серии).
- **Правка серии vs вхождения:** (A) серией целиком — *выбрано* (MVP, тестируемо);
  (B) per-occurrence (EXDATE/override) — отложено (сложность).
- **Бюджет/AI:** (A) reminder только для разовых событий — *выбрано* (чёткая граница);
  (B) бюджет на каждом, в т.ч. recurring — отклонено (бессмысленно для серии).
- **UI:** (A) месячная сетка `table_calendar` — *выбрано* (по требованию); (B)
  агенда-список — отклонено пользователем.

## 10. Риски и допущения

- Полный recurrence без EXDATE: нельзя отменить одно вхождение серии (напр. перенос
  одной встречи) — только правка серии. Документировано; per-occurrence — отдельная
  задача.
- Правка события не ре-синкает связанное `ai_reminder` (создание/удаление — да).
  Документировано.
- `table_calendar` — новая фронт-зависимость; проверить совместимость с Flutter 3.44
  (`^3.1.x` совместим). `flutter pub get` на этапе реализации.
- Бесконечные повторения (`recur_until=NULL`) безопасны: раскрываются только в
  запрошенный месячный диапазон + defensive cap.
