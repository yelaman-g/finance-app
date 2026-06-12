# Быстрая регистрация через Google (Android) — design

Дата: 2026-06-13
Статус: согласован
Подсистема: аутентификация (этап 1 ТЗ — замечание комиссии о «быстрой регистрации»)

## 1. Цель и контекст

Комиссия отметила отсутствие быстрой регистрации как критический недостаток.
Нужно дать вход «в 1–2 нажатия» через Google: на экране входа — крупная кнопка
«Войти через Google», классический email+пароль уходит на второй план (ссылка).
Первый вход через Google автоматически создаёт профиль (имя/аватар из Google),
без длинных форм.

Платформа: **Android** (по ТЗ, цель — Google Play). Backend-эндпоинт един для
всех платформ, поэтому web/iOS можно подключить позже без переделки сервера.

Ключи: реальный Google OAuth Client ID создаётся вне этой среды. Поэтому путь
реализован **config-ready** (включается одной env-переменной) и дополнен
**dev-режимом** — прямым аналогом существующего `devCode` в восстановлении
пароля, чтобы фича работала в тестах и демо без настоящего Google-проекта.

## 2. Границы (scope)

**Входит:**
- Backend `POST /api/v1/auth/google`: верификация Google ID-token, find-or-create
  пользователя, выдача сессии (access + refresh) тем же механизмом, что и login.
- Dev-режим верификации токена (без сети) + dev-путь на фронте.
- Frontend: подключение `google_sign_in` (Android), кнопка «Войти через Google»,
  рестайл экрана входа по ТЗ 5.2.
- Починка `login()` для аккаунтов без пароля (Google-юзеры) — без NPE.
- Миграция БД V14, env-конфиг, тесты (backend + frontend).

**Не входит (отложено отдельными задачами):**
- Пост-логин онбординг «создать/вступить в семью» (экраны household уже есть;
  мягкий nudge добавим отдельной мелкой задачей).
- iOS-настройка Google Sign-In.
- Реальная публикация в Google Play.
- Приведение пригласительного кода к формату `FAM-XXXXXX` (отдельная задача
  «быстрых побед»).

## 3. Модель данных

Миграция **V14** (`V14__google_auth.sql`):
- `users.password_hash` → **nullable** (у Google-аккаунтов нет локального пароля).
- Добавить `users.google_subject VARCHAR(255) UNIQUE NULL` — стабильный
  идентификатор Google-личности (`sub` из ID-token). Привязка по `subject`
  надёжнее, чем только по email.

Поведение полей при входе через Google:
- `email_verified` → `true` (Google уже подтвердил email).
- `avatar_url` → из Google `picture`, только если сейчас пусто (не перетираем
  выбранный пользователем аватар).

Сущность `User`:
- Поле `googleSubject` (nullable), геттер; `password_hash` остаётся `length=100`,
  но колонка становится nullable.
- Конструктор/фабрика для Google-пользователя: `passwordHash = null`,
  `roles = {USER}`, `googleSubject`, `emailVerified = true`, `avatarUrl`.
- Существующий конструктор email+пароля не меняется.

## 4. Логика связывания аккаунтов

`AuthService.loginWithGoogle(GoogleIdentity identity)`:
1. Найти по `google_subject`. Если найден — это вход существующего Google-юзера.
2. Иначе найти по email (`findByEmailIgnoreCase`). Если найден — **привязать**
   Google к существующему аккаунту (в т.ч. к email+пароль): проставить
   `google_subject`, `email_verified=true`, заполнить `avatar_url` при пустом.
3. Иначе — создать нового пользователя (имя/аватар из Google, без пароля).

Во всех трёх случаях: `user.markLoggedIn()` + `issueSession(user)` (access+refresh
с ротацией — переиспользуем существующий код AuthService/RefreshTokenService).

`enabled=false` (заблокированный) → `UnauthorizedException(AUTH_USER_BLOCKED)`,
как в обычном login.

## 5. Backend — API и верификация

**Эндпоинт:** `POST /api/v1/auth/google`
- Тело: `GoogleAuthRequest { String idToken }` (`@NotBlank`).
- Ответ: `ApiResponse<AuthResponse>` (тот же конверт и DTO, что у login/register).
- Добавить путь в `PUBLIC_ENDPOINTS` в `SecurityConfig`.

**Верификация (за интерфейсом, выбор по конфигу):**
```
interface GoogleTokenVerifier {
    GoogleIdentity verify(String idToken);   // email, emailVerified, name, picture, subject
}
```
- `RealGoogleTokenVerifier` (профиль prod / `app.google.dev-mode=false`): поверх
  `GoogleIdTokenVerifier` из `com.google.api-client:google-api-client`,
  audience = `app.google.client-id`. Невалидный/просроченный токен → бросает
  ошибку верификации.
- `DevGoogleTokenVerifier` (`app.google.dev-mode=true`, дефолт в dev): принимает
  токен вида `dev.<base64url(JSON {email,name,picture,sub})>`, парсит без сети.
  Прямой аналог `devCode` в восстановлении пароля.

Выбор реализации — через `@ConditionalOnProperty(app.google.dev-mode)` или явный
`@Configuration`-бин. Тесты используют dev-верификатор либо мок интерфейса.

**Ошибки:** новый `ErrorCode.AUTH_GOOGLE_TOKEN_INVALID`; невалидный токен → HTTP
401 через существующий `GlobalExceptionHandler` (бросаем
`UnauthorizedException`). Если `email_verified=false` в токене — также 401.

**Починка `login()`:** перед `passwordEncoder.matches(...)` проверять
`user.getPasswordHash() == null` → `invalidCredentials()` (иначе NPE). Аккаунт без
пароля может войти только через Google.

**Зависимость:** `com.google.api-client:google-api-client` в `backend/build.gradle`
(нужна только prod-пути; dev/тесты её не задействуют — всё за интерфейсом).

## 6. Frontend (Android)

- `pubspec.yaml`: `google_sign_in: ^6.x`.
- Конфиг через `.env` (flutter_dotenv): `GOOGLE_CLIENT_ID`, `GOOGLE_DEV_MODE`.
  Плагин инициализируется с `serverClientId = GOOGLE_CLIENT_ID` (web/server-client),
  чтобы Android возвращал `idToken` для серверной верификации.
- `AuthRemoteDataSource.signInWithGoogle(String idToken)` → POST `/auth/google`
  (`skipAuth: true`), парсинг конверта как в login/register.
- Новый метод в `AuthRepository` (`signInWithGoogle()`) с маппингом
  `Result/Failure`; новое действие в контроллере (login) — сохраняет токены так же,
  как обычный вход.
- **Dev-режим (`GOOGLE_DEV_MODE=true`):** кнопка НЕ вызывает плагин (на эмуляторе
  без OAuth-client он упадёт), а отправляет `dev.<...>`-токен заранее заданной
  демо-личности → работает в эмуляторе/демо без настоящего Google-проекта.
  Реальный путь включается `GOOGLE_DEV_MODE=false` + заданный `GOOGLE_CLIENT_ID`.

**Рестайл экрана входа (ТЗ 5.2):**
- Сверху — крупная белая кнопка «Войти через Google» с лого Google.
- «Войти с Email» — ссылка (не кнопка), раскрывающая классическую форму
  email+пароль.
- «Забыли пароль?» и «Создать аккаунт» сохраняются.

## 7. Конфигурация (env)

Backend `application.yml`:
```
app:
  google:
    client-id: ${GOOGLE_CLIENT_ID:}
    dev-mode: ${GOOGLE_DEV_MODE:true}
```
Frontend `.env`:
```
GOOGLE_CLIENT_ID=
GOOGLE_DEV_MODE=true
```
Для продакшна (Railway и т.п.) задаются `GOOGLE_CLIENT_ID` и `GOOGLE_DEV_MODE=false`.

## 8. Тестирование (TDD)

**Backend** (MockMvc + Testcontainers, в стиле существующих 119 тестов):
- Новый Google-юзер создаётся (нет ни по subject, ни по email) → 200 + сессия,
  `password_hash IS NULL`, `email_verified=true`.
- Привязка по существующему email (email+пароль аккаунт) → тот же `userId`,
  проставлен `google_subject`.
- Повторный вход по тому же `google_subject` → тот же `userId`.
- Невалидный токен → 401 `AUTH_GOOGLE_TOKEN_INVALID`.
- `email_verified=false` в токене → 401.
- `login()` email+пароль для аккаунта без пароля → 401 (не 500/NPE).
- Verifier подменяется dev-реализацией или моком.

**Frontend** (flutter_test + mocktail):
- `signInWithGoogle` успех → сессия сохранена в репозитории/контроллере.
- Ошибки datasource → корректный `Failure`.
- Виджет-тест экрана входа: кнопка «Войти через Google» присутствует и вызывает
  действие контроллера.

## 9. Рассмотренные альтернативы

- **Модель аккаунта.** Выбран вариант (A): nullable `password_hash` + nullable
  `google_subject`, связывание по email. Отклонены: (B) отдельная таблица
  `user_identities` (гибче для many-providers, избыточно для текущей задачи);
  (C) только `provider`-enum без `subject` (слабее защищает связывание личности).
- **Экран входа.** Выбран вариант (A) по ТЗ 5.2: Google primary + email-ссылка.
  Отклонён (B): оставить форму, кнопку Google снизу (меньше работы, но не
  выполняет требование ТЗ).

## 10. Риски и допущения

- Реальный Google-путь нельзя end-to-end проверить в этой среде без OAuth-client;
  он покрывается за счёт изоляции верификатора интерфейсом (мок/dev в тестах) и
  включается конфигом. Полная проверка реального Google — после получения ключей.
- Dev-режим намеренно небезопасен (принимает неподписанный токен) и должен быть
  выключен в продакшне (`GOOGLE_DEV_MODE=false`), как и dev-код восстановления.
