# AIFB / Family App — запуск проекта с нуля

Инструкция для передачи проекта: как поднять backend (Railway), настроить Google-вход,
push-уведомления (Firebase) и собрать Android-приложение. Все секреты — только в
переменных окружения / конфиг-файлах, никогда не в коде.

---

## 0. Что это за проект

Монорепозиторий:
- **`backend/`** — Spring Boot (Java 21), PostgreSQL, миграции Flyway (выполняются
  автоматически при старте). Деплоится на Railway по корневому `Dockerfile`.
- **`frontend/`** — Flutter (Android — основная цель; есть iOS-конфиги).

Три внешние интеграции, каждая с **dev-режимом** (заглушка) и **реальным** режимом:
| Интеграция | dev-флаг | Что включает реальный режим |
|---|---|---|
| Google-вход | `GOOGLE_DEV_MODE` | проверку реального Google ID-token |
| ИИ-помощник | `AI_DEV_MODE` | реальные ответы Claude (Anthropic) |
| Push | `FCM_DEV_MODE` | реальную доставку через Firebase |

По умолчанию **все три = `true`** (заглушки). Приложение полностью работает в
dev-режиме без единого внешнего аккаунта — это удобно для первого запуска.

---

## 1. Что понадобится (инструменты и аккаунты)

**Инструменты на машине разработчика:**
- Git, JDK 21, Flutter SDK (stable) + Android SDK (Android Studio), `keytool` (идёт с JDK).
- Опционально: Docker (для локального Postgres), Node.js (для `flutterfire_cli`).

**Аккаунты (бесплатные):**
- GitHub — где лежит репозиторий.
- Railway (railway.app) — хостинг backend + PostgreSQL.
- Google Cloud (console.cloud.google.com) — OAuth-вход.
- Firebase (console.firebase.google.com) — push-уведомления.
- Anthropic (console.anthropic.com) — API-ключ для ИИ (платный, по желанию).

---

## 2. Клонирование

```bash
git clone <git-url-репозитория>
cd finance-app
git checkout final     # рабочая ветка проекта
```

> ⚠️ В репозитории **закоммичены** конфиг-файлы с текущими значениями владельца:
> `frontend/.env`, `frontend/android/app/google-services.json`,
> `frontend/lib/firebase_options.dart`, `frontend/ios/Runner/GoogleService-Info.plist`.
> Если поднимаешь **свою** инфраструктуру — эти файлы нужно **заменить** своими
> (шаги ниже). Если хочешь просто запустить на уже существующей — оставь как есть.

---

## 3. Railway — backend + база данных (полный путь)

### 3.1. Аккаунт и проект
1. Зайди на **railway.app** → **Login** (удобнее через GitHub).
2. **New Project** → **Deploy from GitHub repo** → выбери репозиторий (дай Railway
   доступ к нему). Railway создаст сервис из репозитория.

### 3.2. База данных
3. В проекте: **New** → **Database** → **Add PostgreSQL**. Railway поднимет инстанс
   и заведёт переменную-ссылку `Postgres.DATABASE_URL`.

### 3.3. Сервис backend
4. Открой сервис, созданный из репозитория → **Settings**:
   - **Root Directory**: оставь **пустым** (корень репо). Корневой `Dockerfile` и
     `railway.json` уже настроены: builder = Dockerfile, healthcheck = `/actuator/health`.
   - **Build**: ничего вручную не настраивай — `railway.json` всё задаёт.
5. **Variables** (вкладка Variables сервиса backend) — добавь переменные из §6.
   - **Минимум для старта:** подключение к БД + `APP_JWT_SECRET`.
   - Подключение к БД проще всего одной ссылкой:
     `DATABASE_URL` = `${{Postgres.DATABASE_URL}}` (Reference на Postgres-сервис).
     Приложение само распарсит её в host/port/db/user/password.
6. **Deploy** (Railway задеплоит автоматически после добавления переменных или по push).
   - Миграции Flyway (V1…V26) применятся к пустой базе при старте — **схему руками
     создавать не нужно**.
   - Дождись статуса healthcheck → **UP** (эндпоинт `/actuator/health`).
7. **Settings → Networking → Generate Domain** — получишь публичный URL вида
   `https://<имя>.up.railway.app`. Его (с суффиксом `/api/v1`) пропишешь во фронт (§7).

> Симптом «healthcheck: service unavailable» = БД не подключена к backend-сервису
> (не добавлен `DATABASE_URL` / переменные Postgres). Проверь Variables.

---

## 4. Google — вход через Google (полный путь, с нуля)

Схема: Flutter-приложение получает Google **ID-token** (audience = **Web client ID**),
шлёт его на backend; backend проверяет подпись и audience против `GOOGLE_CLIENT_ID`.
Значит нужен **Web-клиент** (его ID идёт и во фронт, и в backend) **и Android-клиент**
(чтобы Google доверял приложению по package + SHA-1).

### 4.1. Аккаунт и проект
1. Нужен обычный Google-аккаунт. Зайди в **console.cloud.google.com**.
2. Вверху **Select a project** → **New Project** → задай имя (напр. `aifb`) → **Create**.

### 4.2. OAuth consent screen (экран согласия)
3. **APIs & Services** → **OAuth consent screen**:
   - User type: **External** → **Create**.
   - Заполни: App name, User support email, Developer contact email.
   - **Scopes**: добавь `openid`, `.../auth/userinfo.email`, `.../auth/userinfo.profile`.
   - **Test users**: добавь Google-почты, которыми будешь логиниться (пока приложение
     не «Published», вход работает только для test users).

### 4.3. SHA-1 подписи приложения
Google и Firebase привязывают Android-клиент к **отпечатку подписи (SHA-1)**.
Релиз сейчас подписывается **debug-ключом** (см. §8), поэтому нужен SHA-1 debug-keystore:
```bash
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android | grep SHA1
# или:
cd frontend/android && ./gradlew signingReport   # ищи вариант Variant: debug → SHA1
```
Скопируй значение SHA1 (формат `AA:BB:CC:...`).

### 4.4. OAuth-клиенты
4. **APIs & Services** → **Credentials** → **Create Credentials** → **OAuth client ID**:
   - **Application type: Android**
     - Package name: **`com.example.aifb`** (см. `frontend/android/app/build.gradle.kts`).
     - SHA-1: вставь из §4.3.
     - Create. (Этот клиент в коде не используется напрямую, но без него Google не
       выдаст токен приложению.)
   - Ещё раз **Create Credentials → OAuth client ID** → **Application type: Web application**
     - Name: напр. `aifb-server`.
     - Create. **Скопируй Client ID этого Web-клиента** — это и есть `GOOGLE_CLIENT_ID`.

### 4.5. Куда вписать
- **Railway (backend):** `GOOGLE_CLIENT_ID` = `<Web client ID>`, `GOOGLE_DEV_MODE` = `false`.
- **Frontend `.env`:** `GOOGLE_CLIENT_ID=<Web client ID>`, `GOOGLE_DEV_MODE=false`
  (фронт передаёт его как `serverClientId`).

> ID-клиента — не секрет (можно коммитить). Никакого `client_secret` для Android-входа
> не требуется.

---

## 5. Firebase — push-уведомления (полный путь, с нуля)

### 5.1. Проект
1. Зайди в **console.firebase.google.com** (тот же Google-аккаунт).
2. **Add project**. Рекомендуется **выбрать уже существующий Google Cloud проект**
   из §4 (тогда Google-вход и Firebase живут в одном проекте) → пройди мастер.

### 5.2. Android-приложение в Firebase
3. На обзоре проекта нажми иконку **Android** («Add app»):
   - Android package name: **`com.example.aifb`**.
   - App nickname: любое.
   - Debug signing certificate SHA-1: вставь SHA-1 из §4.3.
   - **Register app** → **Download `google-services.json`**.
   - Положи файл в **`frontend/android/app/google-services.json`** (заменив существующий).

### 5.3. firebase_options.dart
4. Сгенерируй конфиг для Flutter (заменит существующий `frontend/lib/firebase_options.dart`):
```bash
dart pub global activate flutterfire_cli
cd frontend
flutterfire configure        # выбери свой Firebase-проект и платформы (Android[/iOS])
```
   (iOS: мастер также положит `ios/Runner/GoogleService-Info.plist`.)

### 5.4. Cloud Messaging
5. В Firebase Console: **Build → Cloud Messaging** — убедись, что API включён
   (обычно включается автоматически).

### 5.5. Service account для backend (отправка push)
Backend шлёт push через Firebase Admin SDK по **service-account ключу**:
6. Firebase Console → **⚙ Project settings** → **Service accounts** →
   **Generate new private key** → скачается JSON.
7. **Railway (backend):** добавь переменную `FCM_SERVICE_ACCOUNT_JSON` = **содержимое
   этого JSON целиком** (backend принимает как JSON-контент, так и путь к файлу),
   и `FCM_DEV_MODE` = `false`.
8. **Frontend `.env`:** `FCM_DEV_MODE=false`.

> ⚠️ Этот service-account JSON — **секрет**. Только в переменную Railway, не в git, не в чат.

---

## 6. Полный список переменных Railway (backend)

Добавляются во вкладке **Variables** сервиса backend. Если переменная не задана —
действует значение по умолчанию (в т.ч. dev-режимы = `true`).

| Переменная | Назначение | Значение / пример | Обязательна |
|---|---|---|---|
| `DATABASE_URL` | подключение к БД (одной ссылкой) | `${{Postgres.DATABASE_URL}}` | **да** (или `DB_*` ниже) |
| `DB_URL` | JDBC-URL БД (альтернатива `DATABASE_URL`) | `jdbc:postgresql://host:5432/db` | альтернатива |
| `DB_USER` | пользователь БД | `${{Postgres.PGUSER}}` | с `DB_URL` |
| `DB_PASSWORD` | пароль БД | `${{Postgres.PGPASSWORD}}` | с `DB_URL` |
| `APP_JWT_SECRET` | секрет подписи JWT (base64, длинный) | сгенерируй: `openssl rand -base64 48` | **да** |
| `GOOGLE_CLIENT_ID` | Web OAuth client ID (audience токена) | `123-xxx.apps.googleusercontent.com` | для реального Google |
| `GOOGLE_DEV_MODE` | выкл. заглушку Google | `false` | для реального Google |
| `ANTHROPIC_API_KEY` | ключ Claude | `sk-ant-...` | для реального ИИ |
| `AI_DEV_MODE` | выкл. заглушку ИИ | `false` | для реального ИИ |
| `ANTHROPIC_MODEL` | модель Claude | `claude-sonnet-4-6` (дефолт) | нет |
| `AI_MAX_TOKENS` | лимит ответа ИИ | `2048` (дефолт) | нет |
| `FCM_SERVICE_ACCOUNT_JSON` | ключ Firebase Admin (push) | содержимое service-account JSON | для реального push |
| `FCM_DEV_MODE` | выкл. заглушку push | `false` | для реального push |
| `NOTIFY_CRON` | расписание сканера напоминаний | `0 0 9 * * *` (9:00, дефолт) | нет |
| `NOTIFY_ZONE` | таймзона напоминаний | `Asia/Almaty` (дефолт) | нет |
| `APP_CORS_ORIGINS` | разрешённые origins (для web-клиента) | `https://app.example.com` | нет (для Android не нужно) |
| `SPRING_PROFILES_ACTIVE` | профиль Spring | `prod` (необязательно) | нет |
| `PORT` | порт | **задаёт Railway сам — не трогать** | авто |

**Минимум, чтобы backend поднялся (всё в dev-заглушках):** `DATABASE_URL` + `APP_JWT_SECRET`.
Реальные интеграции включаются добавлением соответствующих пар (`*_DEV_MODE=false` + ключ).

> Напоминание: чтобы реально заработал ИИ, нужны **обе** переменные —
> `AI_DEV_MODE=false` **и** `ANTHROPIC_API_KEY`. Только ключ без `AI_DEV_MODE=false`
> оставит ИИ в заглушке (по умолчанию `AI_DEV_MODE=true`).

---

## 7. Frontend — конфигурация и сборка APK

### 7.1. Зависимости
```bash
cd frontend
flutter pub get
```

### 7.2. `frontend/.env`
Файл уже есть в репо; для своей инфраструктуры приведи к виду:
```dotenv
API_BASE_URL=https://<твой-railway-домен>.up.railway.app/api/v1
GOOGLE_DEV_MODE=false
GOOGLE_CLIENT_ID=<Web client ID из §4.4>
FCM_DEV_MODE=false
```
Локальная разработка: `API_BASE_URL=http://10.0.2.2:9090/api/v1` (Android-эмулятор к
localhost), либо `http://localhost:9090/api/v1` (web/iOS-симулятор).

### 7.3. Конфиг-файлы интеграций
Замени своими (если поднимаешь свою инфраструктуру):
- `frontend/android/app/google-services.json` — из §5.2.
- `frontend/lib/firebase_options.dart` — из §5.3 (`flutterfire configure`).
- `frontend/ios/Runner/GoogleService-Info.plist` — из §5.3 (только iOS).

### 7.4. Сборка и установка
```bash
flutter build apk --release
# установка на подключённое устройство:
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## 8. Подпись приложения (важно для Google/Firebase и Google Play)

Сейчас **release собирается debug-ключом** (`frontend/android/app/build.gradle.kts`:
`release { signingConfig = signingConfigs.getByName("debug") }`). Поэтому в Google и
Firebase регистрируется **SHA-1 debug-keystore** (§4.3) — иначе вход/пуш не заработают
на собранном APK.

Для публикации в Google Play:
1. Создай релизный keystore: `keytool -genkey -v -keystore release.keystore -alias aifb -keyalg RSA -keysize 2048 -validity 10000`.
2. Пропиши `signingConfigs.release` в `build.gradle.kts` (ключ/пароли — через
   `key.properties`, gitignored).
3. Поменяй `applicationId` с `com.example.aifb` на свой уникальный.
4. Зарегистрируй **release SHA-1** (и SHA-256) дополнительно в Google OAuth и Firebase.

---

## 9. Локальный запуск backend (для разработки)

```bash
# Postgres локально (Docker):
docker run --name aifb-pg -e POSTGRES_DB=aifb -e POSTGRES_USER=aifb \
  -e POSTGRES_PASSWORD=aifb -p 5432:5432 -d postgres:16

cd backend
./gradlew bootRun        # дефолты DB_URL/DB_USER/DB_PASSWORD указывают на localhost:5432
# Swagger: http://localhost:9090/swagger ; Health: http://localhost:9090/actuator/health
```
Все dev-флаги по умолчанию `true` — внешние аккаунты для локальной разработки не нужны.

---

## 10. Чек-лист «всё работает по-настоящему»

- [ ] Railway: backend задеплоен, `/actuator/health` → UP, есть публичный домен.
- [ ] Railway Variables: `DATABASE_URL`, `APP_JWT_SECRET` заданы.
- [ ] Google: создан Web + Android OAuth-клиент; `GOOGLE_CLIENT_ID` + `GOOGLE_DEV_MODE=false`
      на Railway и во `frontend/.env`; SHA-1 совпадает с ключом подписи APK.
- [ ] Firebase: `google-services.json` + `firebase_options.dart` заменены своими;
      `FCM_SERVICE_ACCOUNT_JSON` + `FCM_DEV_MODE=false` на Railway; `FCM_DEV_MODE=false` во `.env`.
- [ ] ИИ (по желанию): `ANTHROPIC_API_KEY` + `AI_DEV_MODE=false` на Railway.
- [ ] `frontend/.env` → `API_BASE_URL` указывает на твой Railway-домен.
- [ ] APK собран, установлен, вход через Google и push проверены на устройстве.

---

## 11. Замечания по безопасности (рекомендации)

- **Никогда не клади в git/чат:** `APP_JWT_SECRET`, `ANTHROPIC_API_KEY`,
  `FCM_SERVICE_ACCOUNT_JSON`, релизный keystore и его пароли, Google `client_secret`.
  Их место — переменные Railway / локальный env / gitignored-файлы.
- Сейчас `frontend/.env`, `google-services.json`, `firebase_options.dart`,
  `GoogleService-Info.plist` **закоммичены**. В них нет жёстких секретов (client ID и
  Firebase-конфиг считаются публичными, ограничиваются package + SHA-1), но **рекомендуется**
  вынести `.env` в `.gitignore`, добавить `.env.example` с пустыми значениями и
  пересоздавать `.env` локально.
- Если какой-то ключ был случайно засвечен (в чате/коммите) — **отзови и пересоздай** его.
