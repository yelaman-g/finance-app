# ИИ-помощник по финансам (ТЗ §6) — design

Дата: 2026-06-13
Статус: согласован
Подсистема: ИИ-помощник (этап 4 ТЗ). Headline-фича — приложение «AI Family Budget».

## 1. Цель и контекст

Встроенный ИИ-ассистент на базе **Anthropic Claude API**, специализированный
только на финансах семьи: чат-консультации, анализ бюджета, инсайты/советы,
планы накоплений под событие и напоминания. ИИ не отвечает на посторонние
вопросы (ТЗ §6.2). Финансовый контекст (доходы/расходы) собирает **сам backend**
по текущему пользователю — фронт финданные не шлёт (безопаснее и проще).

На фронте уже есть **готовый скелет** `features/ai_assistant` (экран чата +
лента инсайтов + сущности `AiMessage`/`InsightModel` + riverpod-провайдеры), но
он на мок-данных и не подключён к роутеру. Backend-модуля AI нет.

Ключ Anthropic принадлежит не разработчику — задаётся конфигом окружения
(`ANTHROPIC_API_KEY`), нигде не хардкодится. Модель настраиваемая.

## 2. Границы (scope)

**Входит (весь §6, кроме доставки push):**
- Backend-модуль `ai`: интеграция Claude за портом, сбор финконтекста, эндпоинты
  `/chat`, `/analyze-budget`, `/insights`, `/savings-plan`, CRUD `/reminders`.
- Миграция БД V15 — таблица `ai_reminders`.
- Dev-режим (детерминированные ответы без сети/ключа) для тестов и демо.
- Frontend: подключение скелета `ai_assistant` к реальным эндпоинтам, маршрут
  `/ai` + вход из «Ещё», экраны: чат (есть) + «Анализ бюджета» + «Напоминания»
  (с прогрессом и формой добавления) — ТЗ §6.6.
- Тесты backend (MockMvc + Testcontainers, dev-режим) и frontend (mocktail +
  виджеты).

**Не входит (отложено к этапу FCM, этап 5 ТЗ):**
- **Проактивная доставка push** в 90/30/7/1 дней (cron-планировщик + FCM +
  device-токены). Данные напоминаний, расчёт «сколько откладывать» и их
  отображение в приложении делаются сейчас; FCM подключится к шву
  `notify_days_before` без переделки данных.
- Авто-обновление `saved_amount` из целей (goals) — связывание с goals позже;
  пока `saved_amount` задаётся вручную (необязательное поле).

## 3. Подход и изоляция

Интеграция Claude спрятана за портом `FinanceAdvisor`; реализация выбирается по
`aifb.ai.dev-mode` (паттерн из Google Sign-In, который уже принят):

```java
interface FinanceAdvisor {
    ChatReply       chat(FinanceContext ctx, List<ChatTurn> conversation);
    BudgetAnalysis  analyzeBudget(FinanceContext ctx);
    List<Insight>   insights(FinanceContext ctx);
    SavingsPlan     savingsPlan(FinanceContext ctx, SavingsPlanInput input);
}
```

- **`ClaudeFinanceAdvisor`** (`aifb.ai.dev-mode=false`) — официальный
  **Anthropic Java SDK** (`com.anthropic:anthropic-java`), ключ из
  `ANTHROPIC_API_KEY`, модель из `aifb.ai.model` (дефолт `claude-sonnet-4-6`).
  Системный промпт = ТЗ §6.5 + сериализованный финконтекст; отказ от оффтопа —
  инструкцией в системном промпте. Чат/анализ — текст; инсайты/план накоплений —
  структурированный ответ (Claude structured outputs `output_config.format` с
  JSON-схемой, либо JSON-инструкция + разбор Jackson). Без стриминга,
  `max_tokens ≈ 2048`.
- **`DevFinanceAdvisor`** (`aifb.ai.dev-mode=true`, дефолт) — детерминированные
  ответы, посчитанные из **реальных** финданных, без сети: чат возвращает
  осмысленный финансовый ответ на основе контекста; инсайты/анализ — из
  агрегатов статистики (топ-категория, месяц-к-месяцу, перерасход); план —
  арифметика `(target − saved)/monthsRemaining`. Это аналог dev-кода Google и
  делает тесты/демо рабочими без ключа.

Выбор бина — `@ConditionalOnProperty(prefix="aifb.ai", name="dev-mode", havingValue=...)`,
по образцу `GoogleAuthConfig`.

## 4. Сбор финансового контекста

`FinanceContextBuilder` собирает контекст по `principal.userId()` через
существующий `StatisticsService` (НЕ дублируя его):
- эффективный scope: `FAMILY`, если пользователь в household
  (`HouseholdContextService.membershipOrNull`), иначе `PERSONAL`;
- сводка текущего месяца и прошлого (`summary` за два периода) — для сравнения;
- топ-категории расходов текущего месяца (`byCategory(EXPENSE)`);
- тренд за последние 3–6 месяцев (`trend`);
- валюта пользователя (`UserSettings.currency`, дефолт KZT).

Результат — иммутабельный `FinanceContext` (record), сериализуемый в компактный
текст/JSON для подстановки в промпт. Один билдер используется всеми методами
advisor'а.

## 5. Backend — эндпоинты (`/api/v1/ai`, требуют аутентификации)

Все под `@CurrentUser AuthPrincipal` (НЕ в `PUBLIC_ENDPOINTS`). Конверт
`ApiResponse`.

| Метод | Путь | Тело | Ответ |
|---|---|---|---|
| POST | `/chat` | `ChatRequest{ List<ChatTurn> messages }` (`ChatTurn{role:"user"\|"ai", content}`) | `AiMessageResponse{ role:"ai", content, suggestedActions? }` |
| POST | `/analyze-budget` | `AnalyzeBudgetRequest{ from?, to?, scope? }` | `BudgetAnalysisResponse{ analysis, tips[] }` |
| GET  | `/insights` | `?scope=` | `List<InsightResponse{ id,title,description,type,impactValue?,impactLabel?,createdAt }>` |
| POST | `/savings-plan` | `SavingsPlanRequest{ eventName, eventDate, targetAmount, savedAmount? }` | `SavingsPlanResponse{ monthlyAmount, monthsRemaining, feasible, advice }` |
| GET  | `/reminders` | — | `List<ReminderResponse>` |
| POST | `/reminders` | `CreateReminderRequest{ eventName, eventDate, targetAmount?, savedAmount?, notifyDaysBefore?, shared? }` | `ReminderResponse` |
| DELETE | `/reminders/{id}` | — | `204/ok` |

`ReminderResponse{ id, eventName, eventDate, targetAmount, savedAmount,
notifyDaysBefore, isActive, createdAt, daysUntil, monthsRemaining,
monthlyNeeded, progressPercent }` — производные поля (`daysUntil`,
`monthlyNeeded`, `progressPercent`) считаются на чтении в сервисе (чистая
логика), не хранятся.

Чат **stateless**: фронт присылает историю сообщений; backend подставляет
системный промпт + финконтекст и пересылает разговор в Claude. Серверного
хранения переписки в этом этапе нет (YAGNI).

`AiService` оркестрирует: `FinanceContextBuilder` → `FinanceAdvisor` → ответ.
`ReminderService` — CRUD + расчёт статуса. `ErrorCode` пополняется
`AI_UNAVAILABLE` (ошибка обращения к Claude → 503/502 через
`GlobalExceptionHandler`).

## 6. Модель данных — миграция V15 (`ai_reminders`)

Под конвенции проекта (UUID + `household_id`, а НЕ `BIGINT family_id` как
буквально в ТЗ §6.4 — проект везде на UUID):

```sql
CREATE TABLE ai_reminders (
    id                 UUID PRIMARY KEY,
    user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    household_id       UUID REFERENCES households(id) ON DELETE CASCADE,  -- NULL = личное
    event_name         VARCHAR(200) NOT NULL,
    event_date         DATE NOT NULL,
    target_amount      DECIMAL(14,2),
    saved_amount       DECIMAL(14,2) NOT NULL DEFAULT 0,
    notify_days_before INTEGER[] NOT NULL DEFAULT '{90,30,7,1}',
    is_active          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at         TIMESTAMP NOT NULL,
    updated_at         TIMESTAMP NOT NULL
);
CREATE INDEX idx_ai_reminders_user ON ai_reminders(user_id);
CREATE INDEX idx_ai_reminders_household ON ai_reminders(household_id);
```

Сущность `AiReminder extends BaseEntity` (как остальные доменные сущности).
`notify_days_before` — Postgres `INTEGER[]` (Hibernate `@Array`/`@JdbcTypeCode`);
если массив усложнит — допустимо хранить CSV-строкой и парсить (решение в плане).

## 7. Конфигурация

`application.yml` (namespace `aifb.*`):
```yaml
aifb:
  ai:
    model: ${ANTHROPIC_MODEL:claude-sonnet-4-6}
    dev-mode: ${AI_DEV_MODE:true}
    max-tokens: 2048
```
Ключ — `ANTHROPIC_API_KEY` из окружения (читает Anthropic SDK; в коде —
`@Value("${ANTHROPIC_API_KEY:}")`, передаётся в клиент). Дефолт `dev-mode=true`:
демо/тесты работают без ключа; реальный Claude включается `AI_DEV_MODE=false` +
заданным `ANTHROPIC_API_KEY`. Зависимость `com.anthropic:anthropic-java` в
`backend/build.gradle` (нужна только prod-пути; dev/тесты её не задействуют — всё
за портом).

> Модель по умолчанию `claude-sonnet-4-6` — соответствует ТЗ (стек: «claude-sonnet»)
> и дешевле Opus на чужом ключе; меняется одной переменной `ANTHROPIC_MODEL`.

## 8. Frontend

- **Datasource → реальные эндпоинты:** `ai_remote_data_source.dart` бьёт в
  `/ai/chat`, `/ai/insights`, `/ai/analyze-budget`, `/ai/savings-plan`,
  `/ai/reminders` вместо моков. Чат шлёт историю сообщений (фронт держит её в
  `AiChatNotifier`). Финконтекст НЕ собирается на фронте.
- **Роутер:** подключить `AppRoutes.ai` (`/ai`) в `app_router.dart`; вход —
  пунктом `InsetTile` в «Ещё» (`more_page.dart`), иконка `Icons.auto_awesome`.
- **Экраны §6.6:** `/ai` — контейнер с вкладками: «Чат» (существующий экран
  чата+инсайтов), «Анализ бюджета» (вызывает `/analyze-budget`, показывает
  анализ+советы), «Напоминания» (список из `/reminders` с прогресс-барами + форма
  добавления + удаление). Новые DTO/сущности на фронте: `BudgetAnalysis`,
  `SavingsPlan`, `Reminder` (freezed).
- **Конфиг фронта:** AI работает через тот же `dioProvider` (JWT); отдельный
  `aiDioProvider` из скелета заменяется на общий аутентифицированный `dio`.

## 9. Системный промпт (ТЗ §6.5)

База (подставляется в каждый запрос Claude, + финконтекст):
> «Ты финансовый помощник семейного приложения Family App. Помогаешь семье вести
> бюджет, планировать накопления и напоминать о важных событиях. Отвечай только
> на вопросы о финансах, бюджете и планировании. Если спрашивают о другом —
> вежливо объясни, что специализируешься только на финансах семьи. Используй
> данные о доходах и расходах из контекста запроса. Давай конкретные цифры и
> практические советы.»

## 10. Тестирование (TDD)

- **Backend** (MockMvc + Testcontainers, dev-режим активен по умолчанию):
  - `DevFinanceAdvisorTest` (юнит) — детерминированные инсайты/план из контекста.
  - `FinanceContextBuilderTest` — корректный сбор сводок/тренда для scope.
  - IT на каждый эндпоинт `/ai/*` в dev-режиме: `/chat` (отвечает, не пусто),
    `/analyze-budget`, `/insights` (карточки), `/savings-plan` (арифметика),
    CRUD `/reminders` (создание/чтение с расчётом daysUntil/monthlyNeeded/
    progress, удаление, scope личное/семейное).
  - Advisor подменяется dev-реализацией; реальный Claude в тестах не вызывается.
- **Frontend** (flutter_test + mocktail): repo/datasource тесты на каждый метод
  (успех → маппинг сущностей; ошибка → Failure); виджет-тесты экранов «Анализ
  бюджета» и «Напоминания» (рендер + форма вызывает контроллер).

## 11. Рассмотренные альтернативы

- **Сбор контекста:** (A) backend собирает сам по principal — *выбрано*
  (безопасно, не дублирует данные на клиенте); (B) фронт шлёт финданные —
  отклонено (утечка/дублирование).
- **Память чата:** (A) stateless, фронт шлёт историю — *выбрано* (YAGNI); (B)
  серверная таблица переписки — отклонено для этого этапа.
- **Изоляция Claude:** (A) порт `FinanceAdvisor` + dev/real по конфигу —
  *выбрано* (тестируемо без сети, как Google); (B) прямой вызов SDK в сервисе —
  отклонено (нетестируемо, нет демо без ключа).
- **`notify_days_before`:** Postgres `INTEGER[]` (точнее) vs CSV-строка (проще) —
  выбор в плане; интерфейс DTO одинаков (`List<Integer>`).

## 12. Риски и допущения

- Реальный путь Claude нельзя прогнать в CI без ключа/сети; покрыт изоляцией
  (dev-advisor/мок в тестах), включается конфигом. Полная проверка реального
  Claude — после установки `ANTHROPIC_API_KEY` владельцем.
- Структурированный разбор ответа Claude (инсайты/план) может дать невалидный
  JSON — снижается structured outputs или строгой JSON-инструкцией + дефолтным
  фоллбэком при ошибке парсинга (вернуть пустой список инсайтов, а не 500).
- Push-доставка напоминаний отложена к FCM (этап 5); до тех пор напоминания
  видны только в приложении. Это зафиксировано в DEPLOYMENT.md.
- Стоимость токенов несёт владелец ключа; дефолтная модель — Sonnet (дешевле),
  `max_tokens` ограничен 2048.
