# FCM push-уведомления (ТЗ этап 5) — design

Дата: 2026-06-13
Статус: согласован
Подсистема: FCM push (этап 5 ТЗ). Средний приоритет, подсистема 2 из 2
(первая — семейный календарь, влита в `final`).

## 1. Цель и контекст

Проактивная доставка уведомлений на устройство:
- **AI-напоминания** (`ai_reminders`) — за `notify_days_before` дней до события
  (дефолт `90,30,7,1`). Шов уже готов: поле `notify_days_before` хранится как CSV.
- **События календаря** (`events`) — за настраиваемое число дней (новое поле
  `notify_days_before`, дефолт `1,0` = за 1 день и в день события); для
  повторяющихся — по ближайшему вхождению.

Push/FCM/device-токенов в проекте нет (greenfield). Планировщика
(`@Scheduled`/Quartz) нет — добавляется `@EnableScheduling`.

**Внешняя зависимость (важно).** Реальная доставка FCM требует Firebase-проекта,
`google-services.json`/`GoogleService-Info.plist`, service-account-кредов и
физического устройства. В среде разработки реальная доставка **не проверяется**.
Поэтому система строится **config-ready + dev/log-fallback** — точно как
`GOOGLE_DEV_MODE` (Google-вход) и `AI_DEV_MODE` (ИИ-помощник): по умолчанию
работает без сети и кредов (логирует), реальный FCM включается одним env-флагом.

## 2. Границы (scope)

**Входит:**
- Backend-модуль `notification`: миграция V17 (`device_tokens`,
  `sent_notifications`, `ALTER events ADD notify_days_before`), порт `PushSender`
  (dev-лог / реальный FCM за `@ConditionalOnProperty`), `NotificationScheduler`
  (ежедневный скан двух источников), `NotificationService` (дедуп + отправка),
  эндпоинты `/api/v1/push/**`.
- Frontend: `firebase_core` + `firebase_messaging`, `PushService` (init под guard,
  dev-стаб токена / реальный FCM-токен), регистрация токена на backend, тоггл
  «Уведомления» в настройках, поле тайминга в форме события.
- Тесты backend (дата-математика порогов, дедуп, регистрация токена, dev-отправка,
  оба источника) и frontend (dev-регистрация токена, тоггл).

**Не входит:**
- **Реальная доставка FCM и её проверка** — требует Firebase-проекта и устройства;
  реальный путь реализован и задокументирован, но не верифицируется в этой среде.
- **Rich/actionable-уведомления** (кнопки, картинки, deep-link в конкретный экран) —
  доставляется простое title/body + `data`-payload; навигация по тапу — позже.
- **Тихие часы / гранулярные настройки на источник** — opt-in бинарный (есть токен =
  получаешь push); посточниковые предпочтения — отдельная задача.
- **In-app foreground-баннер кастомного вида** — в dev показываем системное/лог;
  кастомный foreground-UI вне MVP.

## 3. Модель данных — миграция V17 `push`

Конвенции проекта (UUID + version + timestamps, как `ai_reminders`/`events`):

```sql
CREATE TABLE device_tokens (
    id          UUID PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token       VARCHAR(512) NOT NULL UNIQUE,   -- FCM registration token
    platform    VARCHAR(16) NOT NULL DEFAULT 'ANDROID',  -- ANDROID|IOS|WEB
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    version     BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_device_tokens_user ON device_tokens (user_id);

CREATE TABLE sent_notifications (
    id              UUID PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source_type     VARCHAR(16) NOT NULL,   -- REMINDER|EVENT
    source_id       UUID NOT NULL,          -- ai_reminder.id или event.id
    occurrence_date DATE NOT NULL,          -- дата вхождения/события, к которому уведомление
    threshold_day   INTEGER NOT NULL,       -- за сколько дней (0 = в день)
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_sent UNIQUE (source_type, source_id, occurrence_date, threshold_day)
);
CREATE INDEX idx_sent_user ON sent_notifications (user_id);

ALTER TABLE events ADD COLUMN notify_days_before VARCHAR(60) NOT NULL DEFAULT '1,0';
```

- `device_tokens`: у пользователя несколько устройств; `token` уникален глобально
  (один токен — одно устройство; при смене владельца upsert переназначает user_id).
- `sent_notifications`: ключ идемпотентности — `(source_type, source_id,
  occurrence_date, threshold_day)`. Гарантирует «ровно один раз» даже при рестарте
  планировщика или двойном прогоне.
- `events.notify_days_before`: CSV-список как в `ai_reminders` (та же конвенция
  парсинга). `'1,0'` = за 1 день + в день. Пустая строка → не уведомлять.

Сущности: `DeviceToken extends BaseEntity` (version/timestamps — как в SQL выше).
`SentNotification` — **минимальный append-only лог-`@Entity`** (id + user_id +
source_type + source_id + occurrence_date + threshold_day + sent_at), НЕ `BaseEntity`
(version/updated_at логу не нужны — строка не меняется после вставки). Enum
`DevicePlatform {ANDROID, IOS, WEB}`,
`NotificationSource {REMINDER, EVENT}` (`@Enumerated(STRING)`).
`Event` получает поле `notifyDaysBefore` (CSV) + парсер `getNotifyDaysBefore()`
(скопировать паттерн из `AiReminder`). `CreateEventRequest` **уже** содержит
`List<Integer> notifyDaysBefore` (использовался для AI-напоминания) — переиспользуем
его и для push-тайминга события; добавить поле нужно в `UpdateEventRequest` и
`EventResponse`. Дефолт при `null`/пустом на событии — `'1,0'`.

## 4. Порт `PushSender` (dev/real split)

Интерфейс (чистый порт, как `FinanceAdvisor`/`GoogleTokenVerifier`):

```java
public interface PushSender {
    /** @return true если доставлено/принято; false если токен невалиден (удалить). */
    PushResult send(String token, String title, String body, Map<String,String> data);
}
public record PushResult(boolean accepted, boolean tokenInvalid) {}
```

- `DevPushSender` — `@ConditionalOnProperty(name="aifb.fcm.dev-mode", havingValue="true", matchIfMissing=true)`:
  логирует `[FCM-DEV] → token=… title=… body=…`, всегда `accepted=true`. Без сети,
  без кредов. Дефолт для тестов/демо.
- `FcmPushSender` — `@ConditionalOnProperty(name="aifb.fcm.dev-mode", havingValue="false")`:
  Firebase Admin SDK (`com.google.firebase:firebase-admin`). На старте инициализирует
  `FirebaseApp` из service-account JSON (`aifb.fcm.credentials`); **fail-fast при
  пустом пути** (как `RealGoogleTokenVerifier` при пустом clientId). На отправке —
  `FirebaseMessaging.send(Message)`; код ошибки `UNREGISTERED`/`INVALID_ARGUMENT`
  → `tokenInvalid=true`.

`matchIfMissing=true` только для dev-варианта (безопасный дефолт = не слать реально);
реальный вариант требует явного `dev-mode=false`.

## 5. Планировщик и сервис отправки

**`NotificationScheduler`** (`@Component`, `@Scheduled(cron="${aifb.fcm.cron:0 0 9 * * *}")`,
зона из `application.yml`). Дефолт — ежедневно 09:00. Метод `scanAndSend()`:
1. **Напоминания.** `ai_reminders` где `active=true`: для каждого `daysUntil =
   DAYS.between(today, eventDate)`; если `daysUntil ∈ notifyDaysBeforeList` и
   `daysUntil >= 0` → кандидат `(REMINDER, id, eventDate, daysUntil)`.
2. **События.** Пропускаем события с `ai_reminder_id != null` — их дата уже покрыта
   связанным напоминанием (иначе двойное уведомление). Для остальных: ближайшее
   вхождение `>= today` через `RecurrenceExpander.occurrences(start, freq, interval,
   until, today, today+maxThreshold)`; для найденной даты `occ`: `daysUntil =
   DAYS.between(today, occ)`; если `daysUntil ∈ event.notifyDaysBeforeList` → кандидат
   `(EVENT, id, occ, daysUntil)`.
3. Передаёт кандидатов в `NotificationService.deliver(candidates)`.

Метод `scanAndSend()` публичный — вызывается и по расписанию, и из теста/`POST /push/test`-инфраструктуры напрямую (без ожидания cron).

**`NotificationService.deliver(candidate)`** (`@Transactional`):
1. Проверка дедупа: если строка в `sent_notifications` по ключу уже есть → skip.
2. Резолв токенов: `device_tokens` пользователя-владельца (для семейных напоминаний/
   событий — токены всех членов семьи; для личных — только владельца).
3. По каждому токену `pushSender.send(...)`; если `tokenInvalid` → удалить токен.
4. Если хоть одна отправка `accepted` (или нет токенов в dev — всё равно) → вставить
   `sent_notifications` (ключ идемпотентности). Вставку оборачиваем перехватом
   `DataIntegrityViolationException` (гонка с уникальным ключом → уже отправлено).

Заголовки/тексты (MVP): напоминание — «Скоро: <eventName>» / «До события <N> дн.».
Событие — «<title>» / «Через <N> дн.» либо «Сегодня». `data` несёт `{type, id}` для
будущей навигации. (Обогащение тела суммой накоплений `<monthlyNeeded>` — позже,
когда push доставляется реально; сейчас в dev тело только логируется.)

## 6. Эндпоинты `/api/v1/push/**` (под JWT, `@CurrentUser`)

| Метод | Путь | Тело | Ответ |
|---|---|---|---|
| POST | `/push/tokens` | `RegisterTokenRequest{ @NotBlank token, platform(DevicePlatform=ANDROID) }` | `ok` (upsert по token) |
| DELETE | `/push/tokens/{token}` | — | `ok` (снятие при logout/opt-out) |
| POST | `/push/test` | — | `ok` (тест-push себе всеми токенами; удобно для демо/проверки связки) |

- `POST /tokens` — upsert: если токен есть — переустановить `user_id`/`platform`/
  `updated_at`; иначе создать. Идемпотентно.
- `PushController` под JWT (НЕ в `PUBLIC_ENDPOINTS`).
- `ErrorCode` уже имеет нужные коды (`VALIDATION_FAILED`/`NOT_FOUND`) — новых нет.

## 7. Frontend

- Зависимости: `firebase_core`, `firebase_messaging`.
- **Config-ready конфиги:** placeholder `android/app/google-services.json` и
  `ios/Runner/GoogleService-Info.plist` (явно dummy-значения, в комментарии/доке —
  «заменить на реальные из Firebase Console для прода»). Нужны, чтобы сборка с
  плагином не падала.
- **`PushService`** (`lib/features/notifications/`): инициализация Firebase под
  `try/catch` (guard — при невалидном dummy-конфиге не валим приложение). Режим из
  `.env` `FCM_DEV_MODE`:
  - dev: регистрирует **синтетический** токен (`dev-<uuid/ник>`) на
    `POST /push/tokens` (аналог dev-токена Google) — связка проверяется без Firebase.
  - prod: `FirebaseMessaging.instance.getToken()`, регистрация, подписка на
    `onTokenRefresh` (перерегистрация) и `onMessage`/`onMessageOpenedApp` (приём).
- **Тоггл «Уведомления»** в настройках (`UserSettings`-экран или «Ещё»): включение
  регистрирует токен, выключение — `DELETE /push/tokens/{token}`.
- **Поле тайминга в форме события** (`event_form.dart`): «Уведомлять за (дни)» —
  ввод/чипы; шлётся как `notifyDaysBefore` в `CreateEventRequest`. Дефолт `1,0`.

## 8. Обработка ошибок

- Невалидный/протухший токен (`UNREGISTERED`) → удаляем из `device_tokens`.
- Сбой одной отправки логируется, **батч не прерывается** (остальные кандидаты/токены
  обрабатываются).
- Реальный FCM при пустых кредах в режиме `dev-mode=false` → fail-fast на старте.
- Гонка вставки `sent_notifications` (уникальный ключ) → перехват, трактуется как
  «уже отправлено».
- Flutter: ошибка init Firebase (dummy-конфиг) ловится — push-функции просто неактивны,
  приложение работает.

## 9. Тестирование (TDD)

- **Backend** (JUnit + MockMvc + Testcontainers):
  - `NotificationSchedulerTest` (юнит, замоканный `NotificationService`): дата-математика
    — для заданных `today`/`eventDate`/`notifyDaysBefore` срабатывают нужные пороги;
    повторяющееся событие → ближайшее вхождение; пустой `notify_days_before` → ничего.
  - `NotificationServiceIT`: дедуп — повторный `deliver` того же кандидата не плодит
    отправок (`DevPushSender` считает вызовы); невалидный токен удаляется; семейный
    источник шлёт всем членам.
  - `PushApiIT`: регистрация токена (upsert идемпотентен), снятие, `/push/test`,
    auth required (401 без JWT).
  - `DevPushSenderTest`: формат лога/возврата.
- **Frontend** (flutter_test + mocktail):
  - `PushService` dev-режим: регистрирует синтетический токен через мок-datasource.
  - Тоггл настроек: вкл → register, выкл → delete (мок-репозиторий).
  - Форма события: `notifyDaysBefore` уходит в запрос.
- **Реальная доставка FCM** — не проверяется в этой среде (документировано в
  DEPLOYMENT.md).

## 10. Рассмотренные альтернативы

- **Дедуп:** (A) лог-таблица `sent_notifications` с уникальным ключом — *выбрано*
  (ровно-однократно при рестартах/двойных прогонах); (B) «последний порог» на строке
  reminder/event — отклонено (колонки в двух таблицах, грубее); (C) без персистентности,
  «раз в день» — отклонено (дубли при рестарте/редеплое).
- **Тайминг событий:** (A) настраиваемое `notify_days_before` на событии — *выбрано*
  (гибко, единообразно с напоминаниями); (B) фикс «за 1 день + в день» — отклонено
  (менее гибко). Дефолт поля `'1,0'` сохраняет простое поведение «из коробки».
- **Глубина:** (A) config-ready + dev/log-fallback — *выбрано* (тестируемо без Firebase,
  один флаг до прода, паттерн Google/AI); (B) полная Firebase-интеграция сейчас —
  отклонено (не проверяема без кредов/устройства, риск сборки).
- **Flutter-клиент:** добавляем `firebase_messaging` сейчас с placeholder-конфигом —
  *выбрано пользователем* (config-ready на клиенте); чистый seam без плагина —
  отклонено (хотели реальную проводку готовой).

## 11. Риски и допущения

- Placeholder `google-services.json`/`GoogleService-Info.plist` — dummy; реальная
  сборка под прод требует замены. Без реального конфига `flutter build apk`/`ios`
  может вести себя ограниченно; `flutter test`/`analyze` не затронуты (native-плагин
  не вызывается в тестах — `PushService` мокается).
- Реальная доставка не верифицируется здесь — это документированное ограничение среды,
  не дефект.
- `@Scheduled` cron в одном инстансе — при горизонтальном масштабировании понадобится
  лидер-элекшн/шард (вне MVP; для дипломного одно-инстансного деплоя не актуально).
- Зона времени cron берётся из конфигурации; «09:00» — серверная зона.
