# Push о новых семейных расходах — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** При добавлении семейного расхода (shared EXPENSE) остальные члены семьи получают push через готовую FCM-инфраструктуру.

**Architecture:** `TransactionService.create()` после сохранения публикует доменное событие `SharedExpenseCreatedEvent`; слушатель `@TransactionalEventListener(AFTER_COMMIT)` в модуле `notification` вызывает новый `NotificationService.notifyFamilyExpense(...)`, который шлёт push всем членам семьи кроме автора (без дедупа — событие разовое).

**Tech Stack:** Spring Boot 3.3.5 / Java 21, Spring `ApplicationEventPublisher` + `@TransactionalEventListener`, Testcontainers + JUnit.

**Соглашения (для исполнителя):**
- Worktree: `/Users/rik/Documents/asp/finance-app/.claude/worktrees/expense-push` (ветка `feature/expense-push`).
- Backend-тесты (Docker для Testcontainers): `cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests "<pattern>"`.
- `AbstractIntegrationTest` НЕ `@Transactional` (каждый тест коммитит реальные данные) → `@TransactionalEventListener(AFTER_COMMIT)` срабатывает синхронно при прямом вызове `service.create(...)` до возврата из метода.
- `DevPushSender` активен в тестах (dev-режим по умолчанию), бин `PushSender`; синглтон на класс — накапливает отправки между тестами (использовать **уникальные** строки токенов на тест + `anyMatch`/`noneMatch` по токену, либо дельту размера в пределах одного теста).
- Настройка семьи в ИТ: `householdService.create(ownerId, new CreateHouseholdRequest("С")).inviteCode()` → `householdService.join(memberId, new JoinHouseholdRequest(code))`; `householdId` владельца — `householdContext.membershipOrNull(ownerId).householdId()`.
- Семейная категория: `categoryService.list(userId, CategoryType.EXPENSE, Scope.FAMILY).get(0).id()` (аналогично PERSONAL / INCOME).

---

## File Structure

- **Создать:**
  - `backend/src/main/java/com/aifb/platform/finance/transaction/event/SharedExpenseCreatedEvent.java` — доменное событие (record).
  - `backend/src/main/java/com/aifb/platform/notification/service/ExpenseNotificationListener.java` — `@TransactionalEventListener(AFTER_COMMIT)`.
- **Изменить:**
  - `backend/src/main/java/com/aifb/platform/notification/service/NotificationService.java` — метод `notifyFamilyExpense(...)`.
  - `backend/src/main/java/com/aifb/platform/finance/transaction/service/TransactionService.java` — внедрить `ApplicationEventPublisher`, публиковать событие в `create()`.
- **Тесты:**
  - `backend/src/test/java/com/aifb/platform/notification/FamilyExpenseNotifyIT.java` (Task 1).
  - `backend/src/test/java/com/aifb/platform/notification/ExpenseNotificationListenerIT.java` (Task 2).

---

## Task 1: `NotificationService.notifyFamilyExpense` + IT (fan-out минус автор)

**Files:**
- Modify: `backend/src/main/java/com/aifb/platform/notification/service/NotificationService.java`
- Test: `backend/src/test/java/com/aifb/platform/notification/FamilyExpenseNotifyIT.java`

- [ ] **Step 1: Write the failing IT**

`FamilyExpenseNotifyIT.java`:
```java
package com.aifb.platform.notification;

import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdService;
import com.aifb.platform.notification.domain.DevicePlatform;
import com.aifb.platform.notification.service.DevPushSender;
import com.aifb.platform.notification.service.NotificationService;
import com.aifb.platform.notification.service.PushSender;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class FamilyExpenseNotifyIT extends AbstractIntegrationTest {

    @Autowired NotificationService notifications;
    @Autowired HouseholdService householdService;
    @Autowired HouseholdContextService householdContext;
    @Autowired PushSender pushSender;
    @Autowired TestAuth testAuth;

    @Test
    void notifiesMembersExceptAuthor() {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser member = testAuth.createUser();
        String code = householdService.create(owner.id(), new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(member.id(), new JoinHouseholdRequest(code));
        UUID householdId = householdContext.membershipOrNull(owner.id()).householdId();

        String ownerTok = "tok-owner-" + owner.id();
        String memberTok = "tok-member-" + member.id();
        notifications.registerToken(owner.id(), ownerTok, DevicePlatform.ANDROID);
        notifications.registerToken(member.id(), memberTok, DevicePlatform.ANDROID);

        DevPushSender dev = (DevPushSender) pushSender;
        notifications.notifyFamilyExpense(householdId, owner.id(), new BigDecimal("1500.00"), "Продукты");

        assertThat(dev.sent()).anyMatch(s -> s.token().equals(memberTok));
        assertThat(dev.sent()).noneMatch(s -> s.token().equals(ownerTok));
    }

    @Test
    void noRecipientsNoSend() {
        TestAuth.AuthedUser solo = testAuth.createUser();
        String code = householdService.create(solo.id(), new CreateHouseholdRequest("Одиночка")).inviteCode();
        UUID householdId = householdContext.membershipOrNull(solo.id()).householdId();
        String tok = "tok-solo-" + solo.id();
        notifications.registerToken(solo.id(), tok, DevicePlatform.ANDROID);

        DevPushSender dev = (DevPushSender) pushSender;
        // автор — единственный член семьи → после исключения автора получателей нет
        notifications.notifyFamilyExpense(householdId, solo.id(), new BigDecimal("100"), null);

        assertThat(dev.sent()).noneMatch(s -> s.token().equals(tok));
    }
}
```

- [ ] **Step 2: Run, verify it FAILS (метода ещё нет)**

Run: `cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests "com.aifb.platform.notification.FamilyExpenseNotifyIT"`
Expected: компиляция падает — `notifyFamilyExpense` не существует.

- [ ] **Step 3: Implement `notifyFamilyExpense` в NotificationService**

В `NotificationService.java` добавить импорт `java.math.BigDecimal` и метод (после `deliver(...)`):
```java
    /** Немедленный push о новом семейном расходе всем членам семьи, КРОМЕ автора. Без дедупа. */
    @Transactional
    public void notifyFamilyExpense(UUID householdId, UUID authorUserId, BigDecimal amount, String note) {
        if (householdId == null) {
            return;
        }
        List<UUID> recipients = users.findByHouseholdId(householdId).stream()
                .map(User::getId)
                .filter(id -> !id.equals(authorUserId))
                .toList();
        if (recipients.isEmpty()) {
            return;
        }
        List<DeviceToken> deviceTokens = tokens.findByUserIdIn(recipients);
        String body = (note == null || note.isBlank())
                ? money(amount) + " ₸"
                : money(amount) + " ₸ — " + note;
        Map<String, String> data = Map.of("type", "EXPENSE");
        for (DeviceToken dt : deviceTokens) {
            PushResult r = pushSender.send(dt.getToken(), "Новый семейный расход", body, data);
            if (r.tokenInvalid()) {
                tokens.delete(dt);
            }
        }
    }

    private static String money(BigDecimal a) {
        BigDecimal s = a.stripTrailingZeros();
        if (s.scale() < 0) {
            s = s.setScale(0);
        }
        return s.toPlainString();
    }
```
(`₸` = ₸, `—` = тире. Импорт `java.math.BigDecimal` добавить к существующим импортам.)

- [ ] **Step 4: Run, verify PASS**

Run: `cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests "com.aifb.platform.notification.FamilyExpenseNotifyIT"`
Expected: 2 теста PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/aifb/platform/notification/service/NotificationService.java backend/src/test/java/com/aifb/platform/notification/FamilyExpenseNotifyIT.java
git commit -m "feat(fcm): NotificationService.notifyFamilyExpense — push о семейном расходе всем кроме автора"
```

---

## Task 2: Событие + публикация в TransactionService + слушатель (end-to-end)

**Files:**
- Create: `backend/src/main/java/com/aifb/platform/finance/transaction/event/SharedExpenseCreatedEvent.java`
- Create: `backend/src/main/java/com/aifb/platform/notification/service/ExpenseNotificationListener.java`
- Modify: `backend/src/main/java/com/aifb/platform/finance/transaction/service/TransactionService.java`
- Test: `backend/src/test/java/com/aifb/platform/notification/ExpenseNotificationListenerIT.java`

- [ ] **Step 1: Write the failing end-to-end IT**

`ExpenseNotificationListenerIT.java`:
```java
package com.aifb.platform.notification;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
import com.aifb.platform.finance.transaction.service.TransactionService;
import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.service.HouseholdService;
import com.aifb.platform.notification.domain.DevicePlatform;
import com.aifb.platform.notification.service.DevPushSender;
import com.aifb.platform.notification.service.NotificationService;
import com.aifb.platform.notification.service.PushSender;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class ExpenseNotificationListenerIT extends AbstractIntegrationTest {

    @Autowired TransactionService transactions;
    @Autowired CategoryService categoryService;
    @Autowired NotificationService notifications;
    @Autowired HouseholdService householdService;
    @Autowired PushSender pushSender;
    @Autowired TestAuth testAuth;

    private record Family(UUID owner, UUID member, String ownerTok, String memberTok) {}

    private Family family() {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser member = testAuth.createUser();
        String code = householdService.create(owner.id(), new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(member.id(), new JoinHouseholdRequest(code));
        String ownerTok = "tok-owner-" + owner.id();
        String memberTok = "tok-member-" + member.id();
        notifications.registerToken(owner.id(), ownerTok, DevicePlatform.ANDROID);
        notifications.registerToken(member.id(), memberTok, DevicePlatform.ANDROID);
        return new Family(owner.id(), member.id(), ownerTok, memberTok);
    }

    @Test
    void sharedExpenseNotifiesMembersExceptAuthor() {
        Family f = family();
        UUID cat = categoryService.list(f.owner(), CategoryType.EXPENSE, Scope.FAMILY).get(0).id();
        DevPushSender dev = (DevPushSender) pushSender;

        transactions.create(f.owner(), new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("2500.00"), "Кафе", LocalDate.now(), true));

        assertThat(dev.sent()).anyMatch(s -> s.token().equals(f.memberTok()));
        assertThat(dev.sent()).noneMatch(s -> s.token().equals(f.ownerTok()));
    }

    @Test
    void personalExpenseDoesNotNotify() {
        Family f = family();
        UUID cat = categoryService.list(f.owner(), CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
        DevPushSender dev = (DevPushSender) pushSender;
        int before = dev.sent().size();

        transactions.create(f.owner(), new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("500.00"), "личное", LocalDate.now(), false));

        assertThat(dev.sent().size()).isEqualTo(before);
    }

    @Test
    void familyIncomeDoesNotNotify() {
        Family f = family();
        UUID cat = categoryService.list(f.owner(), CategoryType.INCOME, Scope.FAMILY).get(0).id();
        DevPushSender dev = (DevPushSender) pushSender;
        int before = dev.sent().size();

        transactions.create(f.owner(), new CreateTransactionRequest(
                cat, CategoryType.INCOME, new BigDecimal("9000.00"), "премия", LocalDate.now(), true));

        assertThat(dev.sent().size()).isEqualTo(before);
    }
}
```

- [ ] **Step 2: Run, verify it FAILS**

Run: `cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests "com.aifb.platform.notification.ExpenseNotificationListenerIT"`
Expected: `sharedExpenseNotifiesMembersExceptAuthor` падает — событие/слушатель не подключены (push не уходит). (personal/income-тесты могут проходить, т.к. отправок и так нет.)

- [ ] **Step 3: Создать событие**

`SharedExpenseCreatedEvent.java`:
```java
package com.aifb.platform.finance.transaction.event;

import java.math.BigDecimal;
import java.util.UUID;

/** Опубликовано при создании семейного расхода (shared EXPENSE). Слушается модулем notification. */
public record SharedExpenseCreatedEvent(UUID householdId, UUID authorUserId,
                                        BigDecimal amount, String note) {}
```

- [ ] **Step 4: Публиковать событие в TransactionService**

В `TransactionService.java`:
1. Добавить импорты:
```java
import com.aifb.platform.finance.transaction.event.SharedExpenseCreatedEvent;
import org.springframework.context.ApplicationEventPublisher;
```
2. Добавить поле и параметр конструктора (рядом с остальными зависимостями):
```java
    private final ApplicationEventPublisher events;
```
В конструкторе добавить параметр `ApplicationEventPublisher events` (последним) и `this.events = events;`.
3. В `create(...)` сразу после строки `Transaction saved = repository.save(t);` добавить:
```java
        if (saved.getHouseholdId() != null && saved.getType() == CategoryType.EXPENSE) {
            events.publishEvent(new SharedExpenseCreatedEvent(
                    saved.getHouseholdId(), userId, saved.getAmount(), saved.getNote()));
        }
```
(`CategoryType` уже импортирован в TransactionService.)

- [ ] **Step 5: Создать слушатель**

`ExpenseNotificationListener.java`:
```java
package com.aifb.platform.notification.service;

import com.aifb.platform.finance.transaction.event.SharedExpenseCreatedEvent;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/** Шлёт push о новом семейном расходе ПОСЛЕ коммита создания операции. */
@Component
public class ExpenseNotificationListener {

    private final NotificationService notifications;

    public ExpenseNotificationListener(NotificationService notifications) {
        this.notifications = notifications;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onSharedExpense(SharedExpenseCreatedEvent e) {
        notifications.notifyFamilyExpense(e.householdId(), e.authorUserId(), e.amount(), e.note());
    }
}
```

- [ ] **Step 6: Run, verify PASS**

Run: `cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests "com.aifb.platform.notification.ExpenseNotificationListenerIT"`
Expected: 3 теста PASS (семейный расход → member получает, автор нет; личное → 0; семейный доход → 0).

- [ ] **Step 7: Полный backend-прогон (нет регрессий)**

Run: `cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test`
Expected: BUILD SUCCESSFUL (существующие + 5 новых тестов этой фичи зелёные; особенно `finance.transaction.*` без регрессий от изменения конструктора TransactionService).

- [ ] **Step 8: Commit**

```bash
git add backend/src/main/java/com/aifb/platform/finance/transaction/event/SharedExpenseCreatedEvent.java backend/src/main/java/com/aifb/platform/notification/service/ExpenseNotificationListener.java backend/src/main/java/com/aifb/platform/finance/transaction/service/TransactionService.java backend/src/test/java/com/aifb/platform/notification/ExpenseNotificationListenerIT.java
git commit -m "feat(fcm): семейный расход → событие + AFTER_COMMIT-слушатель → push остальным членам (ТЗ §4)"
```

---

## Task 3: Документация

**Files:**
- Modify: `docs/DEPLOYMENT.md`

- [ ] **Step 1: Дополнить §12 (FCM) про расходы**

В разделе «## 12. Push-уведомления (FCM)» в абзаце про источники добавить, что помимо
AI-напоминаний и событий календаря пуш шлётся при **новом семейном расходе** (shared
EXPENSE) остальным членам семьи (кроме автора); личные операции и доходы — без пуша;
реализовано через доменное событие + `@TransactionalEventListener(AFTER_COMMIT)` (пуш
после коммита операции, без дедупа). Найти первый абзац §12 (после заголовка) и
дописать предложение в конце абзаца — Read файл перед Edit.

- [ ] **Step 2: Commit**

```bash
git add docs/DEPLOYMENT.md
git commit -m "docs(deploy): push о новых семейных расходах в разделе FCM"
```

---

## Заметки по реализации
- **Почему AFTER_COMMIT:** не держим FCM-I/O в транзакции создания операции; не шлём пуш при откате; `finance` и `notification` развязаны через Spring-события.
- **Без дедупа:** событие разовое и уникально по транзакции — `sent_notifications` не используется (в отличие от пороговых напоминаний планировщика).
- **Автор исключён:** `recipients = членыСемьи \ автор`; если после исключения пусто (автор — единственный) — отправок нет.
- **Только семейный EXPENSE:** личные операции (нет получателей) и доходы (INCOME) пуш не шлют.
- **Тесты на DevPushSender** (dev-режим); реальная доставка FCM в этой среде не проверяется.
