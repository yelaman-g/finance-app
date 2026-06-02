# Восстановление пароля (dev-режим) — Design

**Дата:** 2026-06-02
**Ветка:** `feature/hig-redesign`
**Статус:** одобрено к реализации

## Цель

Дать пользователю восстановить доступ, если он забыл пароль: запросить код по email и
задать новый пароль по коду. SMTP в проекте не настроен, поэтому в **dev-режиме** код
возвращается в теле ответа и показывается на экране. В проде это поле заменяется отправкой
письма и становится `null` (точка расширения, не часть текущей задачи).

## Контекст (существующий код)

- Auth-контроллер: `AuthController` под базовым путём **`/api/v1/auth`** (`register`, `login`,
  `refresh`, `logout`, `logout-all`, `me`). Сервис — `AuthService` (BCrypt `PasswordEncoder`,
  `User.incrementTokenVersion()`, `RefreshTokenService.revokeAll`).
- Правило пароля (из `RegisterRequest`): длина 8–72, минимум одна буква и одна цифра
  (`^(?=.*[A-Za-z])(?=.*\d).+$`). Новый пароль обязан проходить то же правило.
- Ошибки: `DomainException(ErrorCode, message)` → единый конверт через `GlobalExceptionHandler`.
  `ErrorCode` — стабильный enum со `status`. Новой ошибке нужен новый код.
- Конверт ответа: `ApiResponse.ok(payload)`; `default-property-inclusion: non_null` (null-поля
  выпадают из JSON).
- Конфиг: `aifb.verification.password-reset-ttl: PT30M` (используем), `code-ttl: PT15M`.
- Последняя миграция — `V12`, следующая — **`V13`**.
- Фронт: маршрут `forgotPassword` (`/auth/forgot`) сейчас `_Placeholder`. Уже существуют
  `ForgotPasswordController` + `ForgotPasswordState` (freezed: `email`, `emailError`,
  `submitting`, `sent`, `failure`) и болванки `AuthRemoteDataSource.forgotPassword(email)` →
  `Future<void>`, `resetPassword({code,newPassword})` → `Future<void>`, плюс
  `AuthRepository.forgotPassword/resetPassword` → `Result<void>`. Эндпоинты-константы:
  `/auth/forgot-password`, `/auth/reset-password` (baseUrl уже включает `/api/v1`).
  Файлы в `lib/features/auth/**` используют **относительные импорты** — новый код в этом
  модуле следует тому же стилю (а не `package:`-импортам, как в других фичах).

## Архитектура

### 1. Хранилище кодов сброса

Миграция `V13__password_reset_codes.sql`:

```sql
CREATE TABLE password_reset_codes (
    id          UUID PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code_hash   VARCHAR(255) NOT NULL,        -- BCrypt-хеш 6-значного кода, не открытый текст
    expires_at  TIMESTAMPTZ NOT NULL,
    used_at     TIMESTAMPTZ,                  -- NULL = активен
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_password_reset_codes_user ON password_reset_codes(user_id);
```

JPA-сущность `PasswordResetCode` + репозиторий `PasswordResetCodeRepository`:
- `Optional<PasswordResetCode> findFirstByUserIdAndUsedAtIsNullOrderByCreatedAtDesc(UUID userId)`
  — активный код пользователя.
- `markAllActiveUsed(UUID userId, Instant now)` (`@Modifying` UPDATE) — гасит прежние коды
  при новом запросе, чтобы за раз был один активный код.

### 2. Сервис восстановления

Новый `PasswordResetService` (отдельный сервис, не раздуваем `AuthService`):

- `ForgotPasswordResult forgotPassword(String email)`:
  1. нормализуем email (`trim().toLowerCase`).
  2. ищем пользователя; **если нет — возвращаем результат с `devCode = null`** (200, не
     раскрываем существование).
  3. есть пользователь: гасим прежние активные коды; генерируем 6-значный код
     (`100000–999999`, генератор `java.security.SecureRandom`); сохраняем BCrypt-хеш с
     `expiresAt = now + password-reset-ttl`; возвращаем `devCode = "<код>"`, `expiresAt`.
  - `ForgotPasswordResult` — record `(String devCode /* nullable, dev-only */, Instant expiresAt /* nullable */)`.
- `void reset(String email, String code, String newPassword)`:
  1. находим пользователя по email; нет → `DomainException(AUTH_RESET_CODE_INVALID)` (не
     раскрываем, какой именно фактор неверен).
  2. берём активный код; нет / `expires_at < now` / BCrypt не совпал →
     `DomainException(AUTH_RESET_CODE_INVALID)`.
  3. совпал: `user.changePassword(passwordEncoder.encode(newPassword))`,
     `user.incrementTokenVersion()` (разлогинивает старые сессии), `refreshTokenService.revokeAll(user)`,
     код → `used_at = now()`.
  - Валидация `newPassword` — на DTO (см. ниже); сервис считает вход уже валидным форматно.

`SecureRandom` инжектируется/создаётся в сервисе; TTL читается из
`@Value("${aifb.verification.password-reset-ttl}") Duration`.

Новый код ошибки: `AUTH_RESET_CODE_INVALID("AUTH_RESET_CODE_INVALID", HttpStatus.BAD_REQUEST)`
в `ErrorCode`.

### 3. Эндпоинты (`AuthController`, публичные — `skipAuth`)

- `POST /api/v1/auth/forgot-password`
  Тело `ForgotPasswordRequest { @NotBlank @Email String email }`.
  Ответ `ApiResponse<ForgotPasswordResponse>`, где
  `ForgotPasswordResponse { String devCode /* null в проде / для неизвестного email */, Instant expiresAt }`.
  Всегда `200`. Поле `devCode` помечено как dev-only в Javadoc.

- `POST /api/v1/auth/reset-password`
  Тело `ResetPasswordRequest { @NotBlank @Email String email; @NotBlank @Pattern("^\\d{6}$") String code;
  @NotBlank @Size(8,72) @Pattern("^(?=.*[A-Za-z])(?=.*\\d).+$") String newPassword }`.
  Ответ `ApiResponse<Void>` (`200`). Неверный/просроченный код → `400 AUTH_RESET_CODE_INVALID`.
  Невалидный формат тела → `400 VALIDATION_FAILED` (стандартный обработчик).

`User` дополняется методом `changePassword(String hash)` (если ещё нет публичного сеттера),
по образцу `incrementTokenVersion`.

### 4. Фронтенд

**Data-слой** (`lib/features/auth/**`, относительные импорты):
- `api_endpoints.dart` — константы уже есть.
- `AuthRemoteDataSource.forgotPassword(String email)` → меняем на `Future<String?>`: после POST
  достаём `data['devCode']` из конверта (`data` может содержать только `expiresAt` → devCode
  отсутствует → `null`). Метод толерантен к `data == null`.
- `AuthRemoteDataSource.resetPassword({required String email, required String code,
  required String newPassword})` → добавляем `email`, тело `{email, code, newPassword}`,
  остаётся `Future<void>`.
- `AuthRepository.forgotPassword({required String email})` → `Future<Result<String?>>`.
- `AuthRepository.resetPassword({required String email, required String code,
  required String newPassword})` → `Future<Result<void>>`.
- Импл — через существующий `_guard`.

**Состояние/контроллер** — расширяем `ForgotPasswordState` (freezed, регенерация build_runner)
и `ForgotPasswordController` под два шага в одном экране:
- enum `ForgotStep { request, reset }`.
- Поля стейта: `step` (по умолч. `request`), `email`/`emailError`/`submitting`/`failure`
  (есть), `devCode` (String?), `code`/`codeError`, `newPassword`/`newPasswordError`,
  `resetSubmitting`, `resetDone`.
- `requestCode()`: валидирует email; при `Ok(devCode)` → `step = reset`, сохраняет `devCode`.
- `reset()`: валидирует код (6 цифр) и пароль (правило как при регистрации); при `Ok` →
  `resetDone = true`; при `Err` — `failure`.
- `backToRequest()`: возврат на шаг request (для «запросить код заново»).

**Экран** `ForgotPasswordPage` (заменяет `_Placeholder` в `app_router.dart`), стиль как
`LoginPage` (`LargeTitleScaffold` + HIG-компоненты):
- Шаг `request`: `HigTextField` email + `HigButton` «Получить код».
- Переход на `reset`: если `devCode != null` — `InsetSection` с моноширинным кодом и подписью
  «dev-режим: в проде код придёт на почту»; если `null` — нейтральный текст «Если email
  зарегистрирован, код отправлен».
- Шаг `reset`: `HigTextField` «Код» + `HigTextField` «Новый пароль» (`obscureText`) +
  `HigButton` «Сбросить пароль» + текст-ссылка «Запросить код заново».
- `resetDone == true` → `SnackBar` «Пароль изменён» + `context.go(AppRoutes.login.path)`.
- Ошибки — в `hig.danger` под формой.

Маршрут `verifyEmail` (`/auth/verify`) не трогаем — он вне этой задачи.

## Поток данных

```
Пользователь → forgot-password {email}
  → PasswordResetService.forgotPassword → (есть user) сохраняет hash(code), TTL 30м
  → ApiResponse{ devCode, expiresAt }      (dev: код виден; неизвестный email: devCode=null)
Пользователь → reset-password {email, code, newPassword}
  → PasswordResetService.reset → сверка BCrypt + TTL → новый passwordHash + bump tokenVersion + revokeAll
  → 200                                     (неверно/просрочено → 400 AUTH_RESET_CODE_INVALID)
Фронт: requestCode → шаг reset (показ devCode) → reset → go(login)
```

## Обработка ошибок

| Ситуация | Поведение |
|---|---|
| Неизвестный email на forgot | 200, `devCode = null` (не раскрываем существование) |
| Невалидный email/формат тела | 400 `VALIDATION_FAILED` (бин-валидация) |
| Неверный/просроченный/использованный код | 400 `AUTH_RESET_CODE_INVALID` |
| Новый пароль не проходит правило | 400 `VALIDATION_FAILED` |
| Успешный reset | 200; старые сессии инвалидированы (tokenVersion++ + revokeAll) |

## Тестирование

**Бэкенд** (MockMvc + Testcontainers, как в существующих auth-тестах):
1. forgot существующего email → 200, `devCode` присутствует (6 цифр).
2. forgot несуществующего email → 200, `devCode == null`.
3. reset валидным кодом → 200; логин новым паролем проходит, старым — `401`.
4. повторный reset тем же кодом → `400 AUTH_RESET_CODE_INVALID` (одноразовость).
5. reset неверным кодом → `400 AUTH_RESET_CODE_INVALID`.
6. reset просроченным кодом → `400` (код с `expires_at` в прошлом — через ручную вставку/часы).
7. новый запрос forgot гасит прежний код: старый код после повторного forgot → `400`.

**Фронт** (mocktail, как в существующих тестах контроллеров):
1. `requestCode` с `Ok(devCode)` → `step == reset`, `devCode` в стейте.
2. `requestCode` с `Ok(null)` → `step == reset`, `devCode == null`.
3. `reset` с `Ok` → `resetDone == true`.
4. `reset` с `Err` → `failure` выставлен, `resetDone == false`.
5. валидация: пустой/короткий пароль или код не 6 цифр → ошибки полей, репозиторий не вызван.

## Вне области (YAGNI)

- Реальная отправка email/SMTP (точка расширения: заменить `devCode` на отправку и null).
- Rate-limiting запросов кода, капча.
- Подтверждение email (`verifyEmail`) — отдельная задача.
- Уведомление пользователю «ваш пароль изменён».
