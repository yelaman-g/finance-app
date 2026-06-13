# Семейный календарь / события (ТЗ этап 7) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Семейный календарь с событиями (дни рождения/встречи/расписание), повторениями (раскрытие на сервере), месячной сеткой на фронте; разовое событие с бюджетом создаёт связанный `ai_reminder`.

**Architecture:** Backend-модуль `event` (entity + миграция V16 + `RecurrenceExpander` + `EventService` со scope как у `goal`/`ai`); эндпоинты `/api/v1/events`. Повторения раскрываются на сервере в запрошенный диапазон. Frontend-фича `calendar` на `table_calendar` (месячная сетка) через аутентифицированный `dioProvider`.

**Tech Stack:** Java 21, Spring Boot 3.3.5, JPA, Flyway, Testcontainers + MockMvc · Flutter (Dart 3), Riverpod, Dio, go_router, table_calendar, flutter_test + mocktail.

**Спека:** `docs/superpowers/specs/2026-06-13-calendar-events-design.md`

---

## Окружение и соглашения

- Worktree ONLY: `/Users/rik/Documents/asp/finance-app/.claude/worktrees/calendar` (ветка `feature/calendar`). Не трогать другие чекауты/worktree.
- Backend gradle (JDK 21; если `gradlew` не исполняемый — `chmod +x backend/gradlew`): `cd <worktree>/backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew <args>`. Docker запущен (Testcontainers).
- Frontend (flutter не в PATH): `export PATH="/opt/homebrew/bin:$PATH" && cd <worktree>/frontend && flutter <args>` (Flutter 3.44.0).
- Конвенции backend: `ApiResponse`, `@CurrentUser AuthPrincipal principal` (`principal.userId()`), `BaseEntity` (UUID id + created_at/updated_at/version), миграции в стиле V6 (`created_at/updated_at TIMESTAMPTZ NOT NULL DEFAULT now()`, `version BIGINT NOT NULL DEFAULT 0`). IT extends `AbstractIntegrationTest`; `TestAuth.createUser()` → `AuthedUser` record `(UUID id, String email, String bearer)` — `user.id()`, `user.bearer()`.
- **Уже есть в `final` (этот worktree):** модуль `ai` с `ReminderService` (`create(UUID userId, CreateReminderRequest)→ReminderResponse`, `delete(UUID userId, UUID id)`), `CreateReminderRequest(eventName, eventDate, targetAmount, savedAmount, notifyDaysBefore, shared)`, `ReminderResponse.id()`. `HouseholdContextService` (`membershipOrNull`, `requireManageSharedContent`, `HouseholdContext.householdId()/.canManageSharedContent()`). `DomainException(ErrorCode, String)`, `ErrorCode.VALIDATION_FAILED`, `NotFoundException`, `ForbiddenException`. Образец scope-CRUD — `GoalService`.

---

## Файловая структура

**Backend — создать (`com.aifb.platform.event`):**
- `domain/Event.java`, `domain/EventType.java`, `domain/RecurFreq.java`
- `repository/EventRepository.java`
- `service/RecurrenceExpander.java`, `service/EventService.java`
- `api/EventController.java` + `api/dto/{CreateEventRequest,UpdateEventRequest,EventResponse,EventOccurrenceResponse}.java`
- `db/migration/V16__events.sql`
- Тесты: `event/RecurrenceExpanderTest.java`, `event/EventApiIT.java`

**Frontend — создать (`lib/features/calendar/`):**
- `data/dto/event_dtos.dart`, `data/data_sources/event_remote_data_source.dart`, `data/repositories/event_repository_impl.dart`, `domain/repositories/event_repository.dart`
- `presentation/providers/calendar_providers.dart`, `presentation/pages/calendar_page.dart`, `presentation/widgets/event_form.dart`
- Тесты: `test/features/calendar/event_repository_test.dart`, `test/features/calendar/calendar_page_test.dart`

**Frontend — изменить:** `pubspec.yaml` (table_calendar), `lib/core/network/api_endpoints.dart`, `lib/app/router/app_router.dart`, `lib/features/more/presentation/pages/more_page.dart`, `docs/DEPLOYMENT.md`.

---

# ФАЗА A — BACKEND

## Task A1: Миграция V16 + сущность Event + enum'ы + репозиторий

**Files:** Create `backend/src/main/resources/db/migration/V16__events.sql`, `backend/src/main/java/com/aifb/platform/event/domain/{Event,EventType,RecurFreq}.java`, `backend/src/main/java/com/aifb/platform/event/repository/EventRepository.java`

- [ ] **Step 1: V16__events.sql**
```sql
CREATE TABLE events (
    id              UUID PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    household_id    UUID REFERENCES households(id) ON DELETE CASCADE,
    title           VARCHAR(200) NOT NULL,
    description     VARCHAR(2000),
    start_date      DATE NOT NULL,
    start_time      TIME,
    all_day         BOOLEAN NOT NULL DEFAULT TRUE,
    type            VARCHAR(16) NOT NULL DEFAULT 'OTHER',
    recur_freq      VARCHAR(8) NOT NULL DEFAULT 'NONE',
    recur_interval  INTEGER NOT NULL DEFAULT 1,
    recur_until     DATE,
    ai_reminder_id  UUID REFERENCES ai_reminders(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    version         BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_events_user ON events (user_id);
CREATE INDEX idx_events_household ON events (household_id);
```

- [ ] **Step 2: EventType.java + RecurFreq.java**
```java
package com.aifb.platform.event.domain;
public enum EventType { BIRTHDAY, MEETING, SCHOOL, OTHER }
```
```java
package com.aifb.platform.event.domain;
public enum RecurFreq { NONE, DAILY, WEEKLY, MONTHLY, YEARLY }
```

- [ ] **Step 3: Event.java**
```java
package com.aifb.platform.event.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

@Entity
@Table(name = "events")
public class Event extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "household_id")
    private UUID householdId;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(length = 2000)
    private String description;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "start_time")
    private LocalTime startTime;

    @Column(name = "all_day", nullable = false)
    private boolean allDay = true;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private EventType type = EventType.OTHER;

    @Enumerated(EnumType.STRING)
    @Column(name = "recur_freq", nullable = false, length = 8)
    private RecurFreq recurFreq = RecurFreq.NONE;

    @Column(name = "recur_interval", nullable = false)
    private int recurInterval = 1;

    @Column(name = "recur_until")
    private LocalDate recurUntil;

    @Column(name = "ai_reminder_id")
    private UUID aiReminderId;

    protected Event() {
    }

    public Event(UUID userId, String title, String description, LocalDate startDate,
                 LocalTime startTime, boolean allDay, EventType type,
                 RecurFreq recurFreq, int recurInterval, LocalDate recurUntil) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.title = title;
        this.description = description;
        this.startDate = startDate;
        this.startTime = startTime;
        this.allDay = allDay;
        this.type = type == null ? EventType.OTHER : type;
        this.recurFreq = recurFreq == null ? RecurFreq.NONE : recurFreq;
        this.recurInterval = recurInterval < 1 ? 1 : recurInterval;
        this.recurUntil = recurUntil;
    }

    public UUID getUserId() { return userId; }
    public UUID getHouseholdId() { return householdId; }
    public boolean isShared() { return householdId != null; }
    public void assignHousehold(UUID householdId) { this.householdId = householdId; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public LocalDate getStartDate() { return startDate; }
    public LocalTime getStartTime() { return startTime; }
    public boolean isAllDay() { return allDay; }
    public EventType getType() { return type; }
    public RecurFreq getRecurFreq() { return recurFreq; }
    public int getRecurInterval() { return recurInterval; }
    public LocalDate getRecurUntil() { return recurUntil; }
    public UUID getAiReminderId() { return aiReminderId; }
    public void setAiReminderId(UUID id) { this.aiReminderId = id; }

    public void edit(String title, String description, LocalDate startDate, LocalTime startTime,
                     boolean allDay, EventType type, RecurFreq recurFreq, int recurInterval, LocalDate recurUntil) {
        this.title = title;
        this.description = description;
        this.startDate = startDate;
        this.startTime = startTime;
        this.allDay = allDay;
        this.type = type == null ? EventType.OTHER : type;
        this.recurFreq = recurFreq == null ? RecurFreq.NONE : recurFreq;
        this.recurInterval = recurInterval < 1 ? 1 : recurInterval;
        this.recurUntil = recurUntil;
    }
}
```

- [ ] **Step 4: EventRepository.java**
```java
package com.aifb.platform.event.repository;

import com.aifb.platform.event.domain.Event;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface EventRepository extends JpaRepository<Event, UUID> {
    List<Event> findByUserIdAndHouseholdIdIsNull(UUID userId);
    List<Event> findByHouseholdId(UUID householdId);
}
```

- [ ] **Step 5: Verify schema/entity (SmokeContextIT)**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests "com.aifb.platform.SmokeContextIT"`
Expected: PASS (Flyway применяет V16, JPA validate подтверждает Event↔схема). При расхождении — выровнять колонки/nullability.

- [ ] **Step 6: Commit**
```bash
git add backend/src/main/resources/db/migration/V16__events.sql backend/src/main/java/com/aifb/platform/event/domain backend/src/main/java/com/aifb/platform/event/repository
git commit -m "feat(event): миграция V16 events + сущность Event + enum'ы + репозиторий"
```

---

## Task A2: RecurrenceExpander + юнит-тест

**Files:** Create `backend/src/main/java/com/aifb/platform/event/service/RecurrenceExpander.java`, Test `backend/src/test/java/com/aifb/platform/event/RecurrenceExpanderTest.java`

- [ ] **Step 1: Write the failing test RecurrenceExpanderTest.java**
```java
package com.aifb.platform.event;

import com.aifb.platform.event.domain.RecurFreq;
import com.aifb.platform.event.service.RecurrenceExpander;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class RecurrenceExpanderTest {

    private final RecurrenceExpander expander = new RecurrenceExpander();

    @Test
    void noneInsideRange() {
        var occ = expander.occurrences(LocalDate.of(2026, 6, 10), RecurFreq.NONE, 1, null,
                LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 30));
        assertThat(occ).containsExactly(LocalDate.of(2026, 6, 10));
    }

    @Test
    void noneOutsideRangeEmpty() {
        var occ = expander.occurrences(LocalDate.of(2026, 5, 10), RecurFreq.NONE, 1, null,
                LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 30));
        assertThat(occ).isEmpty();
    }

    @Test
    void weeklyExpandsWithinMonth() {
        // старт 2026-06-01, еженедельно → 1,8,15,22,29 июня
        var occ = expander.occurrences(LocalDate.of(2026, 6, 1), RecurFreq.WEEKLY, 1, null,
                LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 30));
        assertThat(occ).containsExactly(
                LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 8), LocalDate.of(2026, 6, 15),
                LocalDate.of(2026, 6, 22), LocalDate.of(2026, 6, 29));
    }

    @Test
    void yearlyBirthdayShowsOnceInQueriedMonth() {
        // ДР 2000-03-15, ежегодно → в марте 2026 одно вхождение 2026-03-15
        var occ = expander.occurrences(LocalDate.of(2000, 3, 15), RecurFreq.YEARLY, 1, null,
                LocalDate.of(2026, 3, 1), LocalDate.of(2026, 3, 31));
        assertThat(occ).containsExactly(LocalDate.of(2026, 3, 15));
    }

    @Test
    void monthlyFastForwardsFromFarPastStart() {
        // старт 2024-01-31 ежемесячно; запрос июнь 2026 → одно вхождение 2026-06-30 (plusMonths нормализует длину месяца)
        var occ = expander.occurrences(LocalDate.of(2024, 1, 31), RecurFreq.MONTHLY, 1, null,
                LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 30));
        assertThat(occ).hasSize(1);
        assertThat(occ.get(0).getMonthValue()).isEqualTo(6);
    }

    @Test
    void untilBoundStopsExpansion() {
        var occ = expander.occurrences(LocalDate.of(2026, 6, 1), RecurFreq.WEEKLY, 1,
                LocalDate.of(2026, 6, 10),
                LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 30));
        assertThat(occ).containsExactly(LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 8));
    }
}
```

- [ ] **Step 2: Run → FAIL (RecurrenceExpander missing)**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests "com.aifb.platform.event.RecurrenceExpanderTest"`

- [ ] **Step 3: RecurrenceExpander.java**
```java
package com.aifb.platform.event.service;

import com.aifb.platform.event.domain.RecurFreq;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * Раскрывает правило повторения события в конкретные даты внутри [from, to].
 * Чистая логика без зависимостей — тестируется изолированно.
 */
@Component
public class RecurrenceExpander {

    /** Защитный лимит вхождений на одно событие за запрос. */
    private static final int MAX_OCCURRENCES = 400;
    /** Лимит шагов «перемотки» до начала диапазона (страховка от вечного цикла). */
    private static final int FAST_FORWARD_GUARD = 100_000;

    public List<LocalDate> occurrences(LocalDate start, RecurFreq freq, int interval,
                                       LocalDate until, LocalDate from, LocalDate to) {
        List<LocalDate> out = new ArrayList<>();
        if (start == null || from == null || to == null || to.isBefore(from)) {
            return out;
        }
        if (freq == null || freq == RecurFreq.NONE) {
            if (!start.isBefore(from) && !start.isAfter(to)) {
                out.add(start);
            }
            return out;
        }
        LocalDate end = (until != null && until.isBefore(to)) ? until : to;
        int step = Math.max(1, interval);

        // Перемотка к первому вхождению >= from (без накопления вне диапазона).
        LocalDate d = start;
        int guard = 0;
        while (d.isBefore(from) && !d.isAfter(end) && guard < FAST_FORWARD_GUARD) {
            d = advance(d, freq, step);
            guard++;
        }
        // Выдача вхождений в [from, end].
        int count = 0;
        while (!d.isAfter(end) && count < MAX_OCCURRENCES) {
            if (!d.isBefore(from)) {
                out.add(d);
            }
            d = advance(d, freq, step);
            count++;
        }
        return out;
    }

    private LocalDate advance(LocalDate d, RecurFreq freq, int step) {
        return switch (freq) {
            case DAILY -> d.plusDays(step);
            case WEEKLY -> d.plusWeeks(step);
            case MONTHLY -> d.plusMonths(step);
            case YEARLY -> d.plusYears(step);
            case NONE -> d;
        };
    }
}
```

- [ ] **Step 4: Run → PASS (6 тестов)**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests "com.aifb.platform.event.RecurrenceExpanderTest"`

- [ ] **Step 5: Commit**
```bash
git add backend/src/main/java/com/aifb/platform/event/service/RecurrenceExpander.java backend/src/test/java/com/aifb/platform/event/RecurrenceExpanderTest.java
git commit -m "feat(event): RecurrenceExpander (раскрытие повторений в диапазон) + юнит-тесты"
```

---

## Task A3: DTO + EventService (CRUD + scope + раскрытие + AI-связь)

**Files:** Create DTOs в `backend/src/main/java/com/aifb/platform/event/api/dto/` + `service/EventService.java`

- [ ] **Step 1: DTO-записи**
`CreateEventRequest.java`:
```java
package com.aifb.platform.event.api.dto;

import com.aifb.platform.event.domain.EventType;
import com.aifb.platform.event.domain.RecurFreq;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

public record CreateEventRequest(
        @NotBlank @Size(max = 200) String title,
        @Size(max = 2000) String description,
        @NotNull LocalDate startDate,
        LocalTime startTime,
        boolean allDay,
        EventType type,
        RecurFreq recurFreq,
        Integer recurInterval,
        LocalDate recurUntil,
        BigDecimal budget,
        List<Integer> notifyDaysBefore,
        boolean shared) {
}
```
`UpdateEventRequest.java`:
```java
package com.aifb.platform.event.api.dto;

import com.aifb.platform.event.domain.EventType;
import com.aifb.platform.event.domain.RecurFreq;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.time.LocalTime;

public record UpdateEventRequest(
        @NotBlank @Size(max = 200) String title,
        @Size(max = 2000) String description,
        @NotNull LocalDate startDate,
        LocalTime startTime,
        boolean allDay,
        EventType type,
        RecurFreq recurFreq,
        Integer recurInterval,
        LocalDate recurUntil) {
}
```
`EventResponse.java`:
```java
package com.aifb.platform.event.api.dto;

import com.aifb.platform.event.domain.Event;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

public record EventResponse(
        UUID id, String title, String description, LocalDate startDate, LocalTime startTime,
        boolean allDay, String type, String recurFreq, int recurInterval, LocalDate recurUntil,
        boolean shared, UUID aiReminderId) {

    public static EventResponse from(Event e) {
        return new EventResponse(e.getId(), e.getTitle(), e.getDescription(), e.getStartDate(),
                e.getStartTime(), e.isAllDay(), e.getType().name(), e.getRecurFreq().name(),
                e.getRecurInterval(), e.getRecurUntil(), e.isShared(), e.getAiReminderId());
    }
}
```
`EventOccurrenceResponse.java`:
```java
package com.aifb.platform.event.api.dto;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

public record EventOccurrenceResponse(
        UUID eventId, String title, String description, LocalDate date, LocalTime time,
        boolean allDay, String type, boolean recurring) {
}
```

- [ ] **Step 2: EventService.java**
```java
package com.aifb.platform.event.service;

import com.aifb.platform.ai.api.dto.CreateReminderRequest;
import com.aifb.platform.ai.api.dto.ReminderResponse;
import com.aifb.platform.ai.service.ReminderService;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.common.exception.ErrorCode;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.event.api.dto.CreateEventRequest;
import com.aifb.platform.event.api.dto.EventOccurrenceResponse;
import com.aifb.platform.event.api.dto.EventResponse;
import com.aifb.platform.event.api.dto.UpdateEventRequest;
import com.aifb.platform.event.domain.Event;
import com.aifb.platform.event.domain.EventType;
import com.aifb.platform.event.domain.RecurFreq;
import com.aifb.platform.event.repository.EventRepository;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@Service
public class EventService {

    private final EventRepository repository;
    private final HouseholdContextService householdContext;
    private final RecurrenceExpander expander;
    private final ReminderService reminderService;

    public EventService(EventRepository repository,
                        HouseholdContextService householdContext,
                        RecurrenceExpander expander,
                        ReminderService reminderService) {
        this.repository = repository;
        this.householdContext = householdContext;
        this.expander = expander;
        this.reminderService = reminderService;
    }

    @Transactional(readOnly = true)
    public List<EventOccurrenceResponse> list(UUID userId, LocalDate from, LocalDate to, Scope scope) {
        List<Event> events;
        if (scope == Scope.FAMILY) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            events = ctx == null ? List.of() : repository.findByHouseholdId(ctx.householdId());
        } else {
            events = repository.findByUserIdAndHouseholdIdIsNull(userId);
        }
        List<EventOccurrenceResponse> out = new ArrayList<>();
        for (Event e : events) {
            for (LocalDate date : expander.occurrences(e.getStartDate(), e.getRecurFreq(),
                    e.getRecurInterval(), e.getRecurUntil(), from, to)) {
                out.add(new EventOccurrenceResponse(e.getId(), e.getTitle(), e.getDescription(),
                        date, e.getStartTime(), e.isAllDay(), e.getType().name(),
                        e.getRecurFreq() != RecurFreq.NONE));
            }
        }
        out.sort(Comparator.comparing(EventOccurrenceResponse::date)
                .thenComparing(o -> o.time() == null, Comparator.reverseOrder())
                .thenComparing(o -> o.time(), Comparator.nullsLast(Comparator.naturalOrder())));
        return out;
    }

    @Transactional
    public EventResponse create(UUID userId, CreateEventRequest req) {
        RecurFreq freq = req.recurFreq() == null ? RecurFreq.NONE : req.recurFreq();
        if (req.budget() != null && freq != RecurFreq.NONE) {
            throw new DomainException(ErrorCode.VALIDATION_FAILED,
                    "Бюджет доступен только для разовых событий");
        }
        Event event = new Event(userId, req.title(), req.description(), req.startDate(),
                req.startTime(), req.allDay(), req.type() == null ? EventType.OTHER : req.type(),
                freq, req.recurInterval() == null ? 1 : req.recurInterval(), req.recurUntil());
        if (req.shared()) {
            HouseholdContext ctx = householdContext.requireManageSharedContent(userId);
            event.assignHousehold(ctx.householdId());
        }
        // Разовое событие с бюджетом → связанное AI-напоминание.
        if (req.budget() != null) {
            ReminderResponse reminder = reminderService.create(userId, new CreateReminderRequest(
                    req.title(), req.startDate(), req.budget(), BigDecimal.ZERO,
                    req.notifyDaysBefore(), req.shared()));
            event.setAiReminderId(reminder.id());
        }
        return EventResponse.from(repository.save(event));
    }

    @Transactional
    public EventResponse update(UUID userId, UUID id, UpdateEventRequest req) {
        Event event = manageable(userId, id);
        event.edit(req.title(), req.description(), req.startDate(), req.startTime(), req.allDay(),
                req.type() == null ? EventType.OTHER : req.type(),
                req.recurFreq() == null ? RecurFreq.NONE : req.recurFreq(),
                req.recurInterval() == null ? 1 : req.recurInterval(), req.recurUntil());
        return EventResponse.from(repository.save(event));
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        Event event = manageable(userId, id);
        UUID reminderId = event.getAiReminderId();
        repository.delete(event);
        if (reminderId != null) {
            reminderService.delete(userId, reminderId);
        }
    }

    private Event accessible(UUID userId, UUID id) {
        Event event = repository.findById(id)
                .orElseThrow(() -> new NotFoundException("Событие не найдено"));
        if (event.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null || !ctx.householdId().equals(event.getHouseholdId())) {
                throw new NotFoundException("Событие не найдено");
            }
            return event;
        }
        if (!userId.equals(event.getUserId())) {
            throw new NotFoundException("Событие не найдено");
        }
        return event;
    }

    private Event manageable(UUID userId, UUID id) {
        Event event = accessible(userId, id);
        if (event.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null || !ctx.canManageSharedContent()) {
                throw new ForbiddenException("Недостаточно прав для семейного события");
            }
        }
        return event;
    }
}
```

- [ ] **Step 3: Compile**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew compileJava`
Expected: BUILD SUCCESSFUL. (Эндпоинты + IT — следующая задача.)

- [ ] **Step 4: Commit**
```bash
git add backend/src/main/java/com/aifb/platform/event/api/dto backend/src/main/java/com/aifb/platform/event/service/EventService.java
git commit -m "feat(event): DTO + EventService (CRUD, scope, раскрытие, AI-связь для разовых+бюджет)"
```

---

## Task A4: EventController + падающий EventApiIT → зелёный + полный прогон

**Files:** Create `backend/src/main/java/com/aifb/platform/event/api/EventController.java`, Test `backend/src/test/java/com/aifb/platform/event/EventApiIT.java`

- [ ] **Step 1: Write the failing test EventApiIT.java**
```java
package com.aifb.platform.event;

import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MvcResult;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class EventApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired ObjectMapper objectMapper;

    @Test
    void eventsRequireAuth() throws Exception {
        mockMvc.perform(get("/api/v1/events?from=2026-06-01&to=2026-06-30"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void createWeeklyEventExpandsAcrossMonth() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        mockMvc.perform(post("/api/v1/events")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Тренировка\",\"startDate\":\"2026-06-01\",\"allDay\":true,\"recurFreq\":\"WEEKLY\"}"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/v1/events?from=2026-06-01&to=2026-06-30")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(5))   // 1,8,15,22,29 июня
                .andExpect(jsonPath("$.data[0].recurring").value(true));
    }

    @Test
    void oneOffEventWithBudgetCreatesLinkedReminder() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        MvcResult created = mockMvc.perform(post("/api/v1/events")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"День рождения\",\"startDate\":\"2026-09-01\",\"allDay\":true,\"budget\":30000}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.aiReminderId").isNotEmpty())
                .andReturn();

        // напоминание появилось в AI-вкладке
        mockMvc.perform(get("/api/v1/ai/reminders")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].eventName").value("День рождения"));

        // удаление события удаляет напоминание
        String eventId = objectMapper.readTree(created.getResponse().getContentAsString())
                .path("data").path("id").asText();
        mockMvc.perform(delete("/api/v1/events/" + eventId)
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk());
        mockMvc.perform(get("/api/v1/ai/reminders")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(0));
    }

    @Test
    void recurringWithBudgetRejected() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        mockMvc.perform(post("/api/v1/events")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Bad\",\"startDate\":\"2026-06-01\",\"allDay\":true,\"recurFreq\":\"WEEKLY\",\"budget\":1000}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("VALIDATION_FAILED"));
    }
}
```

- [ ] **Step 2: Run → FAIL (нет эндпоинтов /events)**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests "com.aifb.platform.event.EventApiIT"`

- [ ] **Step 3: EventController.java**
```java
package com.aifb.platform.event.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.event.api.dto.CreateEventRequest;
import com.aifb.platform.event.api.dto.EventOccurrenceResponse;
import com.aifb.platform.event.api.dto.EventResponse;
import com.aifb.platform.event.api.dto.UpdateEventRequest;
import com.aifb.platform.event.service.EventService;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/events")
public class EventController {

    private final EventService service;

    public EventController(EventService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<List<EventOccurrenceResponse>> list(
            @CurrentUser AuthPrincipal principal,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(defaultValue = "PERSONAL") Scope scope) {
        return ApiResponse.ok(service.list(principal.userId(), from, to, scope));
    }

    @PostMapping
    public ApiResponse<EventResponse> create(@CurrentUser AuthPrincipal principal,
                                             @Valid @RequestBody CreateEventRequest request) {
        return ApiResponse.ok(service.create(principal.userId(), request));
    }

    @PutMapping("/{id}")
    public ApiResponse<EventResponse> update(@CurrentUser AuthPrincipal principal,
                                             @PathVariable UUID id,
                                             @Valid @RequestBody UpdateEventRequest request) {
        return ApiResponse.ok(service.update(principal.userId(), id, request));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@CurrentUser AuthPrincipal principal, @PathVariable UUID id) {
        service.delete(principal.userId(), id);
        return ApiResponse.ok(null);
    }
}
```
> `/api/v1/events/**` НЕ в `PUBLIC_ENDPOINTS` — требует JWT (тест `eventsRequireAuth`).

- [ ] **Step 4: Run → PASS (4 теста)**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests "com.aifb.platform.event.EventApiIT"`

- [ ] **Step 5: Полный backend-прогон**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test`
Expected: BUILD SUCCESSFUL (все прежние + новые event-тесты).

- [ ] **Step 6: Commit**
```bash
git add backend/src/main/java/com/aifb/platform/event/api/EventController.java backend/src/test/java/com/aifb/platform/event/EventApiIT.java
git commit -m "feat(event): эндпоинты /api/v1/events (CRUD, диапазон, scope) + IT"
```

---

# ФАЗА B — FRONTEND

## Task F1: pubspec (table_calendar) + data-слой + провайдеры

**Files:** Modify `frontend/pubspec.yaml`, `frontend/lib/core/network/api_endpoints.dart`; Create `frontend/lib/features/calendar/data/dto/event_dtos.dart`, `.../data/data_sources/event_remote_data_source.dart`, `.../data/repositories/event_repository_impl.dart`, `.../domain/repositories/event_repository.dart`, `.../presentation/providers/calendar_providers.dart`; Test `frontend/test/features/calendar/event_repository_test.dart`

- [ ] **Step 1: pubspec.yaml — зависимость**
В блок `dependencies:` (в UI-группу, рядом с `table`-подобными — например после `fl_chart`) добавить:
```yaml
  table_calendar: ^3.1.2
```

- [ ] **Step 2: api_endpoints.dart — путь**
В секцию AI/после неё добавить:
```dart
  // Calendar / events
  static const String events = '/events';
```

- [ ] **Step 3: event_dtos.dart**
```dart
class EventOccurrence {
  const EventOccurrence({
    required this.eventId,
    required this.title,
    this.description,
    required this.date,
    this.time,
    required this.allDay,
    required this.type,
    required this.recurring,
  });
  final String eventId;
  final String title;
  final String? description;
  final DateTime date;
  final String? time; // "HH:mm" или null
  final bool allDay;
  final String type; // BIRTHDAY|MEETING|SCHOOL|OTHER
  final bool recurring;

  factory EventOccurrence.fromJson(Map<String, dynamic> j) => EventOccurrence(
        eventId: j['eventId'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        date: DateTime.parse(j['date'] as String),
        time: j['time'] as String?,
        allDay: j['allDay'] as bool? ?? true,
        type: j['type'] as String? ?? 'OTHER',
        recurring: j['recurring'] as bool? ?? false,
      );
}

class EventDetail {
  const EventDetail({required this.id, required this.title});
  final String id;
  final String title;
  factory EventDetail.fromJson(Map<String, dynamic> j) =>
      EventDetail(id: j['id'] as String, title: j['title'] as String);
}
```

- [ ] **Step 4: domain/repositories/event_repository.dart**
```dart
import '../../data/dto/event_dtos.dart';

abstract class EventRepository {
  Future<List<EventOccurrence>> getEvents(DateTime from, DateTime to);
  Future<EventDetail> createEvent(Map<String, dynamic> body);
  Future<void> deleteEvent(String id);
}
```

- [ ] **Step 5: data/data_sources/event_remote_data_source.dart**
```dart
import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../dto/event_dtos.dart';

abstract class EventRemoteDataSource {
  Future<List<EventOccurrence>> getEvents(DateTime from, DateTime to);
  Future<EventDetail> createEvent(Map<String, dynamic> body);
  Future<void> deleteEvent(String id);
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  EventRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  String _d(DateTime d) => d.toIso8601String().split('T').first;

  @override
  Future<List<EventOccurrence>> getEvents(DateTime from, DateTime to) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.events,
      queryParameters: {'from': _d(from), 'to': _d(to)},
    );
    final data = res.data?['data'];
    if (data is! List) {
      throw DioException(requestOptions: RequestOptions(), message: 'Malformed envelope');
    }
    return data.map((e) => EventOccurrence.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<EventDetail> createEvent(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(ApiEndpoints.events, data: body);
    final data = res.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw DioException(requestOptions: RequestOptions(), message: 'Malformed envelope');
    }
    return EventDetail.fromJson(data);
  }

  @override
  Future<void> deleteEvent(String id) async {
    await _dio.delete<void>('${ApiEndpoints.events}/$id');
  }
}
```

- [ ] **Step 6: data/repositories/event_repository_impl.dart**
```dart
import '../../domain/repositories/event_repository.dart';
import '../data_sources/event_remote_data_source.dart';
import '../dto/event_dtos.dart';

class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(this._remote);
  final EventRemoteDataSource _remote;

  @override
  Future<List<EventOccurrence>> getEvents(DateTime from, DateTime to) =>
      _remote.getEvents(from, to);

  @override
  Future<EventDetail> createEvent(Map<String, dynamic> body) => _remote.createEvent(body);

  @override
  Future<void> deleteEvent(String id) => _remote.deleteEvent(id);
}
```

- [ ] **Step 7: presentation/providers/calendar_providers.dart**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/event_remote_data_source.dart';
import '../../data/dto/event_dtos.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/repositories/event_repository.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepositoryImpl(EventRemoteDataSourceImpl(ref.watch(dioProvider)));
});

/// Первый день видимого месяца календаря.
final focusedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

/// События видимого месяца (± неделя для краёв сетки).
final monthEventsProvider = FutureProvider.autoDispose<List<EventOccurrence>>((ref) {
  final m = ref.watch(focusedMonthProvider);
  final from = DateTime(m.year, m.month, 1).subtract(const Duration(days: 7));
  final to = DateTime(m.year, m.month + 1, 0).add(const Duration(days: 7));
  return ref.watch(eventRepositoryProvider).getEvents(from, to);
});
```

- [ ] **Step 8: Write the failing repo test event_repository_test.dart**
```dart
import 'package:aifb/features/calendar/data/dto/event_dtos.dart';
import 'package:aifb/features/calendar/data/data_sources/event_remote_data_source.dart';
import 'package:aifb/features/calendar/data/repositories/event_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements EventRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late EventRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = EventRepositoryImpl(remote);
  });

  test('getEvents returns occurrences', () async {
    final occ = EventOccurrence(
      eventId: 'e1', title: 'Тренировка', date: DateTime(2026, 6, 8),
      allDay: true, type: 'OTHER', recurring: true,
    );
    when(() => remote.getEvents(any(), any())).thenAnswer((_) async => [occ]);
    final res = await repo.getEvents(DateTime(2026, 6, 1), DateTime(2026, 6, 30));
    expect(res, hasLength(1));
    expect(res.first.title, 'Тренировка');
  });

  test('createEvent forwards body and returns detail', () async {
    when(() => remote.createEvent(any()))
        .thenAnswer((_) async => const EventDetail(id: 'e1', title: 'ДР'));
    final res = await repo.createEvent({'title': 'ДР'});
    expect(res.id, 'e1');
    verify(() => remote.createEvent(any())).called(1);
  });
}
```

- [ ] **Step 9: pub get + repo test + analyze**
`export PATH="/opt/homebrew/bin:$PATH" && cd frontend && flutter pub get` (table_calendar разрешается; если конфликт версий — STOP, report BLOCKED с ошибкой).
`... && flutter test test/features/calendar/event_repository_test.dart` → pass.
`... && flutter analyze lib/features/calendar test/features/calendar` → без ошибок.

- [ ] **Step 10: Commit**
```bash
git add frontend/pubspec.yaml frontend/pubspec.lock frontend/lib/core/network/api_endpoints.dart frontend/lib/features/calendar/data frontend/lib/features/calendar/domain frontend/lib/features/calendar/presentation/providers frontend/test/features/calendar/event_repository_test.dart
git commit -m "feat(calendar-fe): table_calendar, data-слой /events, провайдеры месяца"
```

---

## Task F2: Экран календаря (месячная сетка) + маршрут + «Ещё»

**Files:** Create `frontend/lib/features/calendar/presentation/pages/calendar_page.dart`; Modify `frontend/lib/app/router/app_router.dart`, `frontend/lib/features/more/presentation/pages/more_page.dart`; Test `frontend/test/features/calendar/calendar_page_test.dart`

- [ ] **Step 1: calendar_page.dart**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../data/dto/event_dtos.dart';
import '../providers/calendar_providers.dart';
import '../widgets/event_form.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(monthEventsProvider);
    final events = async.valueOrNull ?? const <EventOccurrence>[];
    List<EventOccurrence> forDay(DateTime d) =>
        events.where((e) => _sameDate(e.date, d)).toList();
    final dayEvents = forDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(title: const Text('Календарь')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await showEventForm(context, ref, initialDate: _selectedDay);
          if (created ?? false) ref.invalidate(monthEventsProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TableCalendar<EventOccurrence>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => _sameDate(d, _selectedDay),
            eventLoader: forDay,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Месяц'},
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) {
              _focusedDay = focused;
              ref.read(focusedMonthProvider.notifier).state =
                  DateTime(focused.year, focused.month, 1);
            },
          ),
          const Divider(height: 1),
          if (async.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: dayEvents.isEmpty
                ? const Center(child: Text('Нет событий на этот день'))
                : ListView.builder(
                    itemCount: dayEvents.length,
                    itemBuilder: (ctx, i) {
                      final e = dayEvents[i];
                      return ListTile(
                        leading: Icon(_icon(e.type)),
                        title: Text(e.title),
                        subtitle: Text(e.allDay ? 'Весь день' : (e.time ?? '')),
                        trailing: e.recurring ? const Icon(Icons.repeat, size: 18) : null,
                        onLongPress: () async {
                          await ref.read(eventRepositoryProvider).deleteEvent(e.eventId);
                          ref.invalidate(monthEventsProvider);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _icon(String type) => switch (type) {
        'BIRTHDAY' => Icons.cake_rounded,
        'MEETING' => Icons.groups_rounded,
        'SCHOOL' => Icons.school_rounded,
        _ => Icons.event_rounded,
      };
}
```
> Удаление — по long-press (MVP). `showEventForm` создаётся в F3 — для компиляции F2 сначала добавь временную заглушку в `event_form.dart` (см. шаг 2).

- [ ] **Step 2: временная заглушка формы** `frontend/lib/features/calendar/presentation/widgets/event_form.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool?> showEventForm(BuildContext context, WidgetRef ref, {required DateTime initialDate}) async {
  return false; // реализуется в F3
}
```

- [ ] **Step 3: app_router.dart — маршрут /calendar**
Импорт: `import '../../features/calendar/presentation/pages/calendar_page.dart';`
Сразу после GoRoute `/ai` (top-level, перед `StatefulShellRoute`) добавить:
```dart
      GoRoute(
        path: AppRoutes.calendar.path,
        name: AppRoutes.calendar.name,
        pageBuilder: (ctx, state) =>
            fadeThroughPage(key: state.pageKey, child: const CalendarPage()),
      ),
```
> Если в `routes.dart` нет `AppRoutes.calendar` — добавь в `routes.dart` рядом с `ai`: `static const calendar = _Route('calendar', '/calendar');`. (Проверь файл; `ai`/`moments` там есть, `calendar` — добавить при отсутствии.)

- [ ] **Step 4: more_page.dart — пункт после «ИИ-помощник» в секции «Управление»**
```dart
            InsetTile(
              title: 'Календарь',
              leading: const Icon(Icons.event_rounded),
              onTap: () => context.push(AppRoutes.calendar.path),
            ),
```

- [ ] **Step 5: Write the failing widget test calendar_page_test.dart**
```dart
import 'package:aifb/app/theme/app_theme.dart';
import 'package:aifb/features/calendar/data/dto/event_dtos.dart';
import 'package:aifb/features/calendar/domain/repositories/event_repository.dart';
import 'package:aifb/features/calendar/presentation/pages/calendar_page.dart';
import 'package:aifb/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements EventRepository {
  @override
  Future<List<EventOccurrence>> getEvents(DateTime from, DateTime to) async => const [];
  @override
  Future<EventDetail> createEvent(Map<String, dynamic> body) async =>
      const EventDetail(id: 'e1', title: 't');
  @override
  Future<void> deleteEvent(String id) async {}
}

void main() {
  testWidgets('CalendarPage renders calendar and empty-day hint', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [eventRepositoryProvider.overrideWithValue(_FakeRepo())],
      child: MaterialApp(theme: AppTheme.light, home: const CalendarPage()),
    ));
    await tester.pump(); // resolve provider future
    expect(find.text('Календарь'), findsOneWidget);
    expect(find.text('Нет событий на этот день'), findsOneWidget);
  });
}
```

- [ ] **Step 6: pub get (если нужно) → widget test → analyze**
`export PATH="/opt/homebrew/bin:$PATH" && cd frontend && flutter test test/features/calendar/calendar_page_test.dart` → PASS.
`... && flutter analyze lib/features/calendar lib/app/router/app_router.dart lib/features/more/presentation/pages/more_page.dart` → без ошибок.

- [ ] **Step 7: Commit**
```bash
git add frontend/lib/features/calendar/presentation frontend/lib/app/router frontend/lib/features/more/presentation/pages/more_page.dart frontend/test/features/calendar/calendar_page_test.dart
git commit -m "feat(calendar-fe): экран месячной сетки + маршрут /calendar + вход из «Ещё»"
```

---

## Task F3: Форма события (создание с повторением/бюджетом)

**Files:** Modify `frontend/lib/features/calendar/presentation/widgets/event_form.dart`

- [ ] **Step 1: Реализация формы** (заменить заглушку целиком)
> Примечание: у `DropdownButtonFormField` имя параметра текущего значения зависит от версии Flutter (`initialValue` в свежих, `value` в старых). Ниже используется `initialValue:`; если `flutter analyze` ругается — замени на `value:` (то, что компилируется в Flutter 3.44).
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/calendar_providers.dart';

const _types = ['OTHER', 'BIRTHDAY', 'MEETING', 'SCHOOL'];
const _freqs = ['NONE', 'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'];

Future<bool?> showEventForm(BuildContext context, WidgetRef ref,
    {required DateTime initialDate}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _EventForm(initialDate: initialDate, ref: ref),
  );
}

class _EventForm extends StatefulWidget {
  const _EventForm({required this.initialDate, required this.ref});
  final DateTime initialDate;
  final WidgetRef ref;

  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  final _title = TextEditingController();
  final _budget = TextEditingController();
  late DateTime _date = widget.initialDate;
  String _type = 'OTHER';
  String _freq = 'NONE';
  bool _allDay = true;
  bool _saving = false;

  String _d(DateTime d) => d.toIso8601String().split('T').first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('Дата: ${_d(_date)}')),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: const Text('Выбрать'),
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Тип'),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? 'OTHER'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _freq,
              decoration: const InputDecoration(labelText: 'Повтор'),
              items: _freqs
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _freq = v ?? 'NONE'),
            ),
            // Бюджет — только для разовых событий
            if (_freq == 'NONE')
              TextField(
                controller: _budget,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Бюджет (необязательно)'),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final body = <String, dynamic>{
      'title': _title.text.trim(),
      'startDate': _d(_date),
      'allDay': _allDay,
      'type': _type,
      'recurFreq': _freq,
    };
    if (_freq == 'NONE') {
      final b = double.tryParse(_budget.text);
      if (b != null) body['budget'] = b;
    }
    try {
      await widget.ref.read(eventRepositoryProvider).createEvent(body);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось создать событие')),
        );
      }
    }
  }
}
```

- [ ] **Step 2: analyze**
`export PATH="/opt/homebrew/bin:$PATH" && cd frontend && flutter analyze lib/features/calendar/presentation/widgets/event_form.dart`
Expected: без ошибок (устранить лишние lint минимально).

- [ ] **Step 3: Commit**
```bash
git add frontend/lib/features/calendar/presentation/widgets/event_form.dart
git commit -m "feat(calendar-fe): форма события (тип, повтор, бюджет для разовых)"
```

---

## Task F4: Полная верификация + документация

**Files:** Modify `docs/DEPLOYMENT.md`

- [ ] **Step 1: Полный backend-прогон**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test` → BUILD SUCCESSFUL.

- [ ] **Step 2: Полный frontend-прогон**
`export PATH="/opt/homebrew/bin:$PATH" && cd frontend && flutter test` → All tests passed.

- [ ] **Step 3: Frontend analyze (без ошибок)**
`export PATH="/opt/homebrew/bin:$PATH" && cd frontend && flutter analyze 2>/dev/null | grep -cE "^\s+error"` → `0`.

- [ ] **Step 4: DEPLOYMENT.md — обновить число миграций и добавить заметку**
В разделе 3 заменить «миграции `V1…V15`» → «`V1…V16`». Добавить короткий раздел «## 11. Семейный календарь» с описанием: события `/api/v1/events` (под JWT), повторения раскрываются на сервере, месячная сетка во фронте (`table_calendar`), разовое событие с бюджетом создаёт связанное AI-напоминание; правка/удаление — серией; push о событиях — этап FCM. Формулировки в стиле документа.

- [ ] **Step 5: Commit**
```bash
git add docs/DEPLOYMENT.md
git commit -m "docs(deploy): раздел календаря + число миграций V16"
```

---

## Definition of Done

- `/api/v1/events` (GET from/to/scope, POST/PUT/DELETE) под JWT; повторения раскрываются на сервере; разовое событие с бюджетом создаёт/удаляет связанный `ai_reminder`; recurring+бюджет → 400.
- Миграция V16 `events`; `RecurrenceExpander` покрыт юнит-тестами.
- Frontend: фича `calendar` (месячная сетка `table_calendar` + список дня + форма), маршрут `/calendar` + вход из «Ещё», аутентифицированный `dio`.
- Полные наборы тестов (backend + frontend) зелёные; `flutter analyze` без ошибок.
- Календарь задокументирован в `docs/DEPLOYMENT.md`.

## Out of scope

- Правка/отмена отдельного вхождения серии (EXDATE/override).
- Push о событиях (этап FCM — следующая подсистема).
- Ре-синк связанного `ai_reminder` при правке события (создание/удаление — да).
