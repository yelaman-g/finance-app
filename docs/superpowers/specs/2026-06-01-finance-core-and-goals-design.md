# Финансовое ядро + Цели — дизайн серверной части и интеграции

Дата: 2026-06-01
Статус: согласован, готов к планированию реализации

## Контекст

AIFB — дипломный проект (Spring Boot 3.3.5 / Java 21 / PostgreSQL + Flutter Web).
На момент старта реально реализованы только модули `auth` и `admin/db`. Фронтовые
фичи `ai_assistant`, `moments`, `dashboard` работают на клиентских mock-данных;
фич `transactions`, `goals` на фронте нет вовсе.

Цель этой работы — построить **серверную часть финансового ядра и финансовых целей**
и подключить её к Flutter-фронту (заменить mock в дашборде на реальные данные).

Объём согласован как **A + B**: ядро (транзакции, категории, статистика) + цели.
AI-ассистент, лента «Моменты», семейный бюджет — вне объёма.

## Архитектурные решения (зафиксированы)

- **Стиль кода** повторяет модуль `auth` как эталон: feature-модуль с пакетами
  `api` / `api/dto` / `domain` / `repository` / `service`; Flyway-миграции;
  JPA + optimistic locking через `BaseEntity`; конверт ответов `ApiResponse` / `PageResponse`;
  обработка ошибок через `GlobalExceptionHandler` и доменные исключения.
- **Одна валюта на пользователя** (решение A). Суммы хранятся как чистые `NUMERIC`,
  без колонки валюты. Символ валюты подставляется на отображении из `UserSettings.currency`.
  Конвертация и мультивалютность — вне объёма (можно упомянуть в «планах развития»).
- **Категории — гибрид**: системный набор (сидится миграцией, `user_id IS NULL`,
  `is_system = true`) + пользовательские категории (CRUD).
- **Удаление категорий — мягкое** (`deleted_at`). Операции на удалённую категорию
  сохраняются и корректно отображаются в истории/статистике; в списке для выбора
  удалённая категория не появляется.
- **Цели наполняются ручными взносами** (`goal_contributions`). Прогресс = `SUM(amount)`
  взносов, считается на чтение. При достижении `target_amount` статус → `COMPLETED`.
- **Изоляция данных**: всё привязано к `user_id`; доступ к чужому ресурсу → `404`.
- **Статистика встроена в дашборд** — отдельного экрана на фронте нет.

## Модель данных (миграции V4–V7)

### `categories` (V4)
| поле | тип | примечание |
|---|---|---|
| id | UUID PK | |
| user_id | UUID NULL FK→users ON DELETE CASCADE | NULL = системная категория |
| name | VARCHAR(80) NOT NULL | |
| type | VARCHAR(10) NOT NULL | `INCOME` / `EXPENSE` (CHECK) |
| icon | VARCHAR(40) NULL | ключ иконки для фронта |
| color | VARCHAR(9) NULL | hex-цвет |
| is_system | BOOLEAN NOT NULL DEFAULT FALSE | |
| deleted_at | TIMESTAMPTZ NULL | мягкое удаление |
| created_at, updated_at, version | | аудит (как в `BaseEntity`) |

- Частичный уникальный индекс на `(user_id, lower(name), type) WHERE deleted_at IS NULL`.
- Системные категории сидятся в той же миграции:
  - EXPENSE: Еда, Транспорт, Жильё, Развлечения, Здоровье, Покупки, Связь, Прочее.
  - INCOME: Зарплата, Подработка, Подарки, Инвестиции, Прочее.

### `transactions` (V5)
| поле | тип | примечание |
|---|---|---|
| id | UUID PK | |
| user_id | UUID NOT NULL FK→users ON DELETE CASCADE | |
| category_id | UUID NOT NULL FK→categories | без каскада (категории удаляются мягко) |
| type | VARCHAR(10) NOT NULL | `INCOME` / `EXPENSE`, должен совпадать с типом категории |
| amount | NUMERIC(15,2) NOT NULL | CHECK > 0 |
| note | VARCHAR(255) NULL | |
| occurred_on | DATE NOT NULL | дата операции (для агрегаций по месяцам) |
| created_at, updated_at, version | | аудит |

Индексы: `(user_id, occurred_on DESC)`, `(user_id, category_id)`.

### `goals` (V6)
| поле | тип | примечание |
|---|---|---|
| id | UUID PK | |
| user_id | UUID NOT NULL FK→users ON DELETE CASCADE | |
| name | VARCHAR(120) NOT NULL | |
| target_amount | NUMERIC(15,2) NOT NULL | CHECK > 0 |
| deadline | DATE NULL | |
| status | VARCHAR(12) NOT NULL DEFAULT 'ACTIVE' | `ACTIVE`/`COMPLETED`/`ARCHIVED` (CHECK) |
| icon | VARCHAR(40) NULL | |
| color | VARCHAR(9) NULL | |
| created_at, updated_at, version | | аудит |

### `goal_contributions` (V7)
| поле | тип | примечание |
|---|---|---|
| id | UUID PK | |
| goal_id | UUID NOT NULL FK→goals ON DELETE CASCADE | |
| amount | NUMERIC(15,2) NOT NULL | CHECK > 0 |
| note | VARCHAR(255) NULL | |
| contributed_on | DATE NOT NULL | |
| created_at, updated_at, version | | аудит |

Индекс: `(goal_id, contributed_on DESC)`.

## Backend-модули

```
platform/finance/category/     api, api/dto, domain, repository, service
platform/finance/transaction/  api, api/dto, domain, repository, service
platform/finance/statistics/   api, api/dto, service  (своих таблиц нет — агрегации)
platform/finance/goal/         api, api/dto, domain, repository, service
```

## REST API (под `/api/v1`, требует JWT)

### Категории
- `GET /categories?type=EXPENSE` — список (системные + свои, без удалённых).
- `POST /categories` — создать пользовательскую.
- `PUT /categories/{id}` — редактировать свою (системную — `403`).
- `DELETE /categories/{id}` — мягкое удаление своей (системную — `409`/`403`).

### Транзакции
- `GET /transactions?from=&to=&type=&categoryId=&page=&size=` — пагинация
  (`PageResponse`), сортировка по `occurred_on DESC`.
- `GET /transactions/{id}`
- `POST /transactions` — валидация: `type` операции == `type` категории.
- `PUT /transactions/{id}`
- `DELETE /transactions/{id}`

### Статистика
- `GET /statistics/summary?from=&to=` → `{ income, expense, net }`.
- `GET /statistics/by-category?from=&to=&type=EXPENSE`
  → `[{ categoryId, name, color, total, percentage }]`.
- `GET /statistics/trend?from=&to=` → помесячно `[{ month, income, expense }]`.

### Цели
- `GET /goals` — список с прогрессом (`savedAmount`, `percentage`).
- `GET /goals/{id}`
- `POST /goals`
- `PUT /goals/{id}`
- `DELETE /goals/{id}`
- `POST /goals/{id}/contributions` — добавить взнос (пересчёт статуса).
- `GET /goals/{id}/contributions` — история взносов.
- `DELETE /goals/{id}/contributions/{cid}` — удалить взнос.

Ошибки: несовпадение типа операции/категории → `400` (доменный код валидации);
чужой/несуществующий ресурс → `404`; удаление/правка системной категории → `403`/`409`.

## Интеграция во фронт (Flutter)

Стиль — как в существующих фичах: `data` (Dio data source + freezed DTO + mappers),
`domain` (entities + repository), `presentation` (Riverpod controllers/providers + pages/widgets).

- Новые фичи: `features/transactions`, `features/goals`, `features/statistics`
  (statistics — только data/domain + провайдеры, без отдельного экрана).
- Дополнить `lib/core/network/api_endpoints.dart` новыми путями.
- **Заменить mock в `dashboard`** реальными данными:
  - `balance_card` ← `GET /statistics/summary`,
  - `spending_chart_card` ← `GET /statistics/by-category`,
  - `recent_transactions` ← последние транзакции (`GET /transactions?size=N`),
  - `goal_progress_card` ← `GET /goals`.
  - `family_activity_card` и AI-карточка остаются на mock (вне объёма A+B).
- Экраны: список + форма создания транзакций; список целей + форма + добавление взносов.
- Роуты в `lib/app/router/app_router.dart` + `routes.dart`.
- Кодген: `dart run build_runner build --delete-conflicting-outputs`.

## Тестирование

- **Backend**: интеграционные тесты на реальном Postgres через **Testcontainers**
  (добавить зависимости `org.testcontainers:junit-jupiter` и `:postgresql`).
  Миграции используют `pgcrypto` и partial index — H2 не подходит.
  Покрытие: валидация совпадения типов, изоляция по `user_id`, мягкое удаление
  категории и её отсутствие в списке выбора, прогресс целей и авто-`COMPLETED`,
  агрегации статистики (summary / by-category / trend) на фикстуре данных.
- **Frontend**: юнит-тесты репозиториев и контроллеров через `mocktail`
  (маппинг DTO↔entity, обработка ошибок, состояния провайдеров).

## Вне объёма (фиксируем явно)

- AI-ассистент (чат, инсайты) — остаётся на mock.
- Лента «Моменты» — остаётся на mock.
- Семейный бюджет, роли/совместный доступ.
- Мультивалютность и конвертация по курсам (`ExchangeRate`).
- Уведомления/напоминания по целям.

## Известные технические заметки

- Предварительно по ходу запуска уже добавлена миграция `V3__user_settings.sql`
  (не хватало таблицы под существующую сущность `UserSettings`) — нумерация новых
  миграций продолжается с V4.
- В репозитории по ошибке закоммичены build-артефакты (`backend/.gradle/`, `backend/build/`);
  на работу не влияет, при желании можно почистить отдельным коммитом + `.gitignore`.
