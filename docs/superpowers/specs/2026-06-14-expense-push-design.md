# Push о новых семейных расходах (ТЗ §4) — design

Дата: 2026-06-14
Статус: согласован
Контекст: ТЗ §4 — «Push-уведомления … по задачам, событиям, **новым расходам**».
События и AI-напоминания уже закрыты (подсистема FCM). Эта спека добавляет
недостающий триггер — уведомление о новом **семейном расходе**.

## 1. Цель

При добавлении **семейной** (shared) операции типа **расход** (EXPENSE) остальные
члены семьи получают push «появился новый семейный расход». Использует уже готовую
FCM-инфраструктуру (порт `PushSender`, `device_tokens`, dev/log-fallback).

## 2. Границы (scope)

**Входит:**
- Публикация доменного события при создании семейного расхода.
- Слушатель в модуле `notification`, отправляющий push **после коммита** транзакции.
- Метод `NotificationService.notifyFamilyExpense(...)` — fan-out на членов семьи минус автор.
- Тесты (юнит + IT).

**Не входит:**
- Личные операции и доходы (INCOME) — без пуша.
- Уведомления о задачах (модуля «задачи» в backend нет — вне проекта).
- Порог суммы, тихие часы, посточниковые настройки — opt-in уже через наличие
  device-токена и тоггл «Уведомления»; порог — отдельная задача при необходимости.
- UI-изменения, новые env-переменные, миграции — не требуются.
- Дедуп через `sent_notifications` — не нужен: событие разовое и уникально по транзакции.

## 3. Архитектура — событие + AFTER_COMMIT

Выбран подход с доменным событием и `@TransactionalEventListener(phase = AFTER_COMMIT)`:

```
TransactionService.create()
  └─ repository.save(t)
  └─ if (t.isShared() && t.getType()==EXPENSE)
        publisher.publishEvent(new SharedExpenseCreatedEvent(householdId, authorUserId, amount, note))
  └─ (commit)
          └─ ExpenseNotificationListener  @TransactionalEventListener(AFTER_COMMIT)
                └─ notificationService.notifyFamilyExpense(householdId, authorUserId, amount, note)
```

**Почему так (а не прямой вызов в `create()`):**
- FCM-вызовы (реальный режим — HTTP) не держатся внутри транзакции создания операции.
- Push не уходит, если транзакция откатится (AFTER_COMMIT срабатывает только при коммите).
- `finance` не зависит от `notification` напрямую — связь через Spring-события
  (publisher/listener развязаны в рантайме; `notification` слушает `finance`, как уже
  слушает `event`/`ai` в планировщике).

## 4. Компоненты

### `finance/transaction/event/SharedExpenseCreatedEvent`
Доменное событие (record):
```
record SharedExpenseCreatedEvent(UUID householdId, UUID authorUserId,
                                 BigDecimal amount, String note) {}
```

### `TransactionService` (правка)
- Внедрить `ApplicationEventPublisher`.
- В `create(...)` после `Transaction saved = repository.save(t);`: если
  `saved.getHouseholdId() != null && req.type() == CategoryType.EXPENSE` →
  `publisher.publishEvent(new SharedExpenseCreatedEvent(saved.getHouseholdId(), userId,
  saved.getAmount(), saved.getNote()))`.
- Остальная логика `create` без изменений.

### `notification/service/ExpenseNotificationListener`
```
@Component
class ExpenseNotificationListener {
    @TransactionalEventListener(phase = AFTER_COMMIT)
    void onSharedExpense(SharedExpenseCreatedEvent e) {
        notificationService.notifyFamilyExpense(e.householdId(), e.authorUserId(),
                                                e.amount(), e.note());
    }
}
```

### `NotificationService.notifyFamilyExpense(...)` (новый метод, `@Transactional`)
- получатели = `users.findByHouseholdId(householdId)` минус `authorUserId`;
- если получателей нет → выход; токены = `deviceTokens.findByUserIdIn(recipients)`;
- по каждому токену `pushSender.send(token, title, body, data)`; `tokenInvalid` → удалить токен;
- **без записи `sent_notifications`** (разовое событие).

**Текст:** title = «Новый семейный расход»; body = `formatBody(amount, note)` —
«`<amount> ₸ — <note>`» (если `note` пуст — только сумма). `data = {"type": "EXPENSE"}`.
Сумма форматируется без дробной части для целых (как в приложении), символ `₸`.

## 5. Обработка ошибок

- Слушатель работает после коммита в отдельной транзакции — сбой отправки **не влияет**
  на создание операции (она уже сохранена и закоммичена).
- Сбой одной отправки логируется, батч (остальные токены) продолжается.
- Протухший токен (`tokenInvalid`) удаляется из `device_tokens`.
- В dev-режиме (`FCM_DEV_MODE=true`) отправка только логируется (`[FCM-DEV]`).

## 6. Тестирование

- **Юнит `NotificationServiceTest`/IT (notifyFamilyExpense):** при членах {owner, member},
  токен у member → `DevPushSender` получает 1 отправку (member), автор (owner) исключён;
  получателей нет/нет токенов → 0 отправок.
- **IT `ExpenseNotificationIT` (через API, проверяет AFTER_COMMIT):** owner создаёт семью,
  member вступает и регистрирует токен; owner создаёт **семейный расход** через
  `POST /api/v1/transactions` (`shared=true, type=EXPENSE`) → `DevPushSender` фиксирует
  отправку member и НЕ автору; **личный** расход и **семейный доход** → 0 отправок.
  (MockMvc-запрос коммитит реальную транзакцию → AFTER_COMMIT-слушатель срабатывает
  синхронно до возврата ответа.)

## 7. Рассмотренные альтернативы

- **Доставка:** (A) событие + AFTER_COMMIT — *выбрано* (нет I/O в транзакции, нет
  уведомления при откате, развязка модулей); (B) прямой вызов в `create()` — отклонено.
- **Триггер:** (A) только семейный EXPENSE остальным членам — *выбрано* (по ТЗ
  «новым расходам»); (B) +INCOME — отклонено; (C) порог суммы — отложено (нет требования).
- **Дедуп:** не нужен — событие разовое, в отличие от пороговых напоминаний планировщика.

## 8. Риски и допущения

- Высокая частота семейных расходов → много пушей; контроль шума пока только через
  opt-in (токен/тоггл). Порог суммы — будущая задача.
- Имя автора в тексте не показывается (MVP) — экономит запрос к `users`; можно добавить позже.
- Реальная доставка FCM не проверяется в dev-среде (как и в остальной FCM-подсистеме) —
  тесты идут на `DevPushSender`.
