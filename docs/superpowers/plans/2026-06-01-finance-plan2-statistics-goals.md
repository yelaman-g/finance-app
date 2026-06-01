# План 2 — Backend: Статистика + Цели

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Реализовать серверную часть аналитики (сводка / по категориям / помесячный тренд поверх транзакций) и финансовых целей с ручными взносами (прогресс, авто-завершение) с интеграционными тестами.

**Architecture:** Модуль `finance/statistics` не имеет своих таблиц — это агрегирующие запросы по `transactions` (JPQL-проекции + один нативный запрос для помесячного тренда). Модуль `finance/goal` строится по образцу `auth`/`category`: сущности `Goal` и `GoalContribution` наследуют `BaseEntity`, прогресс цели (`savedAmount`) считается как `SUM(amount)` взносов на чтение и не хранится дублем; при достижении `target_amount` статус переходит в `COMPLETED`. Привязка к пользователю — `UUID userId` из `@CurrentUser`.

**Tech Stack:** Spring Boot 3.3.5, Java 21, Spring Data JPA (JPQL + native), PostgreSQL, Flyway, Jakarta Validation; тесты — Testcontainers + MockMvc (инфраструктура из Плана 1).

**Предусловие:** План 1 реализован и смёржен/применён в ветке (есть `transactions`, `categories`, `CategoryType`, `TransactionRepository`, `CategoryRepository`, тестовая инфраструктура `support/AbstractIntegrationTest`, `support/TestAuth`).

---

## Структура файлов

**Изменяемые:**
- `.../finance/category/repository/CategoryRepository.java` — добавить `findByIdIn` (имена категорий для статистики, включая мягко удалённые).
- `.../finance/transaction/repository/TransactionRepository.java` — добавить агрегирующие запросы статистики и проекции.

**Создаваемые — модуль `statistics`:**
- `.../finance/statistics/api/dto/SummaryResponse.java`
- `.../finance/statistics/api/dto/CategoryBreakdownResponse.java`
- `.../finance/statistics/api/dto/TrendPointResponse.java`
- `.../finance/statistics/service/StatisticsService.java`
- `.../finance/statistics/api/StatisticsController.java`

**Создаваемые — миграции:**
- `backend/src/main/resources/db/migration/V6__goals.sql`
- `backend/src/main/resources/db/migration/V7__goal_contributions.sql`

**Создаваемые — модуль `goal`:**
- `.../finance/goal/domain/GoalStatus.java`
- `.../finance/goal/domain/Goal.java`
- `.../finance/goal/domain/GoalContribution.java`
- `.../finance/goal/repository/GoalRepository.java`
- `.../finance/goal/repository/GoalContributionRepository.java`
- `.../finance/goal/service/GoalService.java`
- `.../finance/goal/api/GoalController.java`
- `.../finance/goal/api/dto/GoalResponse.java`
- `.../finance/goal/api/dto/CreateGoalRequest.java`
- `.../finance/goal/api/dto/UpdateGoalRequest.java`
- `.../finance/goal/api/dto/ContributionResponse.java`
- `.../finance/goal/api/dto/CreateContributionRequest.java`

**Создаваемые — тесты** (`backend/src/test/java/com/aifb/platform/...`):
- `finance/statistics/StatisticsServiceIT.java`
- `finance/statistics/StatisticsApiIT.java`
- `finance/goal/GoalServiceIT.java`
- `finance/goal/GoalApiIT.java`

Все команды `./gradlew` запускаются из `backend/` с `JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home`.

---

## Task 1: Агрегирующие запросы статистики (репозитории)

**Files:**
- Modify: `.../finance/transaction/repository/TransactionRepository.java`
- Modify: `.../finance/category/repository/CategoryRepository.java`

- [ ] **Step 1: Добавить проекции и запросы в `TransactionRepository`**

В файл `.../finance/transaction/repository/TransactionRepository.java` добавить импорты и методы (внутри интерфейса, после существующих методов):

Добавить импорты:
```java
import java.math.BigDecimal;
import java.util.List;
```

Добавить вложенные проекции и методы в тело интерфейса:
```java
    interface TypeTotal {
        CategoryType getType();
        BigDecimal getTotal();
    }

    interface CategoryTotal {
        UUID getCategoryId();
        BigDecimal getTotal();
    }

    interface TrendRow {
        String getMonth();
        BigDecimal getIncome();
        BigDecimal getExpense();
    }

    @Query("""
            select t.type as type, coalesce(sum(t.amount), 0) as total
            from Transaction t
            where t.userId = :userId
              and (:from is null or t.occurredOn >= :from)
              and (:to is null or t.occurredOn <= :to)
            group by t.type
            """)
    List<TypeTotal> sumByType(@Param("userId") UUID userId,
                              @Param("from") LocalDate from,
                              @Param("to") LocalDate to);

    @Query("""
            select t.categoryId as categoryId, coalesce(sum(t.amount), 0) as total
            from Transaction t
            where t.userId = :userId
              and t.type = :type
              and (:from is null or t.occurredOn >= :from)
              and (:to is null or t.occurredOn <= :to)
            group by t.categoryId
            order by total desc
            """)
    List<CategoryTotal> sumByCategory(@Param("userId") UUID userId,
                                      @Param("type") CategoryType type,
                                      @Param("from") LocalDate from,
                                      @Param("to") LocalDate to);

    @Query(value = """
            select to_char(occurred_on, 'YYYY-MM') as month,
                   coalesce(sum(amount) filter (where type = 'INCOME'), 0) as income,
                   coalesce(sum(amount) filter (where type = 'EXPENSE'), 0) as expense
            from transactions
            where user_id = :userId
              and (cast(:from as date) is null or occurred_on >= :from)
              and (cast(:to as date) is null or occurred_on <= :to)
            group by 1
            order by 1
            """, nativeQuery = true)
    List<TrendRow> trend(@Param("userId") UUID userId,
                         @Param("from") LocalDate from,
                         @Param("to") LocalDate to);
```

- [ ] **Step 2: Добавить `findByIdIn` в `CategoryRepository`**

В `.../finance/category/repository/CategoryRepository.java` добавить метод (статистике нужны имена категорий, в том числе мягко удалённых):

```java
    List<Category> findByIdIn(Collection<UUID> ids);
```

(`Collection`, `List`, `UUID` уже импортированы в этом файле из Плана 1.)

- [ ] **Step 3: Проверить компиляцию**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew compileJava
```
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 4: Commit**

```bash
git add backend/src/main/java/com/aifb/platform/finance/transaction/repository/TransactionRepository.java backend/src/main/java/com/aifb/platform/finance/category/repository/CategoryRepository.java
git commit -m "feat(statistics): агрегирующие запросы по транзакциям и lookup категорий"
```

---

## Task 2: Статистика — DTO и сервис с тестами

**Files:**
- Create: `.../finance/statistics/api/dto/SummaryResponse.java`
- Create: `.../finance/statistics/api/dto/CategoryBreakdownResponse.java`
- Create: `.../finance/statistics/api/dto/TrendPointResponse.java`
- Create: `.../finance/statistics/service/StatisticsService.java`
- Test: `backend/src/test/java/com/aifb/platform/finance/statistics/StatisticsServiceIT.java`

- [ ] **Step 1: Создать DTO**

Create `.../finance/statistics/api/dto/SummaryResponse.java`:
```java
package com.aifb.platform.finance.statistics.api.dto;

import java.math.BigDecimal;

public record SummaryResponse(BigDecimal income, BigDecimal expense, BigDecimal net) {
}
```

Create `.../finance/statistics/api/dto/CategoryBreakdownResponse.java`:
```java
package com.aifb.platform.finance.statistics.api.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record CategoryBreakdownResponse(
        UUID categoryId,
        String name,
        String color,
        BigDecimal total,
        double percentage) {
}
```

Create `.../finance/statistics/api/dto/TrendPointResponse.java`:
```java
package com.aifb.platform.finance.statistics.api.dto;

import java.math.BigDecimal;

public record TrendPointResponse(String month, BigDecimal income, BigDecimal expense) {
}
```

- [ ] **Step 2: Написать падающий тест сервиса**

Create `backend/src/test/java/com/aifb/platform/finance/statistics/StatisticsServiceIT.java`:
```java
package com.aifb.platform.finance.statistics;

import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.finance.statistics.api.dto.CategoryBreakdownResponse;
import com.aifb.platform.finance.statistics.api.dto.SummaryResponse;
import com.aifb.platform.finance.statistics.api.dto.TrendPointResponse;
import com.aifb.platform.finance.statistics.service.StatisticsService;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
import com.aifb.platform.finance.transaction.service.TransactionService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class StatisticsServiceIT extends AbstractIntegrationTest {

    @Autowired StatisticsService service;
    @Autowired TransactionService transactionService;
    @Autowired CategoryService categoryService;
    @Autowired TestAuth testAuth;

    private void tx(UUID userId, UUID categoryId, CategoryType type, String amount, LocalDate when) {
        transactionService.create(userId, new CreateTransactionRequest(
                categoryId, type, new BigDecimal(amount), null, when));
    }

    @Test
    void summaryComputesIncomeExpenseNet() {
        UUID userId = testAuth.createUser().id();
        UUID expenseId = categoryService.list(userId, CategoryType.EXPENSE).get(0).id();
        UUID incomeId = categoryService.list(userId, CategoryType.INCOME).get(0).id();

        tx(userId, incomeId, CategoryType.INCOME, "1000.00", LocalDate.now());
        tx(userId, expenseId, CategoryType.EXPENSE, "300.00", LocalDate.now());
        tx(userId, expenseId, CategoryType.EXPENSE, "200.00", LocalDate.now());

        SummaryResponse summary = service.summary(userId, null, null);
        assertThat(summary.income()).isEqualByComparingTo("1000.00");
        assertThat(summary.expense()).isEqualByComparingTo("500.00");
        assertThat(summary.net()).isEqualByComparingTo("500.00");
    }

    @Test
    void summaryIsEmptyForNewUser() {
        UUID userId = testAuth.createUser().id();
        SummaryResponse summary = service.summary(userId, null, null);
        assertThat(summary.income()).isEqualByComparingTo("0");
        assertThat(summary.expense()).isEqualByComparingTo("0");
        assertThat(summary.net()).isEqualByComparingTo("0");
    }

    @Test
    void byCategoryReturnsTotalsAndPercentages() {
        UUID userId = testAuth.createUser().id();
        List<com.aifb.platform.finance.category.api.dto.CategoryResponse> cats =
                categoryService.list(userId, CategoryType.EXPENSE);
        UUID c1 = cats.get(0).id();
        UUID c2 = cats.get(1).id();

        tx(userId, c1, CategoryType.EXPENSE, "750.00", LocalDate.now());
        tx(userId, c2, CategoryType.EXPENSE, "250.00", LocalDate.now());

        List<CategoryBreakdownResponse> breakdown =
                service.byCategory(userId, CategoryType.EXPENSE, null, null);
        assertThat(breakdown).hasSize(2);
        // отсортировано по убыванию суммы
        assertThat(breakdown.get(0).total()).isEqualByComparingTo("750.00");
        assertThat(breakdown.get(0).percentage()).isEqualTo(75.0);
        assertThat(breakdown.get(0).name()).isNotBlank();
    }

    @Test
    void trendGroupsByMonth() {
        UUID userId = testAuth.createUser().id();
        UUID incomeId = categoryService.list(userId, CategoryType.INCOME).get(0).id();
        UUID expenseId = categoryService.list(userId, CategoryType.EXPENSE).get(0).id();

        tx(userId, incomeId, CategoryType.INCOME, "1000.00", LocalDate.now());
        tx(userId, expenseId, CategoryType.EXPENSE, "400.00", LocalDate.now());

        List<TrendPointResponse> trend = service.trend(userId, null, null);
        assertThat(trend).isNotEmpty();
        TrendPointResponse current = trend.get(trend.size() - 1);
        assertThat(current.month()).matches("\\d{4}-\\d{2}");
        assertThat(current.income()).isEqualByComparingTo("1000.00");
        assertThat(current.expense()).isEqualByComparingTo("400.00");
    }
}
```

- [ ] **Step 3: Запустить тест — убедиться, что НЕ компилируется/падает**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test --tests 'com.aifb.platform.finance.statistics.StatisticsServiceIT'
```
Expected: FAIL — `StatisticsService` ещё не создан.

- [ ] **Step 4: Создать `StatisticsService`**

Create `.../finance/statistics/service/StatisticsService.java`:
```java
package com.aifb.platform.finance.statistics.service;

import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.repository.CategoryRepository;
import com.aifb.platform.finance.statistics.api.dto.CategoryBreakdownResponse;
import com.aifb.platform.finance.statistics.api.dto.SummaryResponse;
import com.aifb.platform.finance.statistics.api.dto.TrendPointResponse;
import com.aifb.platform.finance.transaction.repository.TransactionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class StatisticsService {

    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;

    public StatisticsService(TransactionRepository transactionRepository,
                             CategoryRepository categoryRepository) {
        this.transactionRepository = transactionRepository;
        this.categoryRepository = categoryRepository;
    }

    @Transactional(readOnly = true)
    public SummaryResponse summary(UUID userId, LocalDate from, LocalDate to) {
        BigDecimal income = BigDecimal.ZERO;
        BigDecimal expense = BigDecimal.ZERO;
        for (TransactionRepository.TypeTotal row : transactionRepository.sumByType(userId, from, to)) {
            if (row.getType() == CategoryType.INCOME) {
                income = row.getTotal();
            } else if (row.getType() == CategoryType.EXPENSE) {
                expense = row.getTotal();
            }
        }
        return new SummaryResponse(income, expense, income.subtract(expense));
    }

    @Transactional(readOnly = true)
    public List<CategoryBreakdownResponse> byCategory(UUID userId, CategoryType type,
                                                      LocalDate from, LocalDate to) {
        List<TransactionRepository.CategoryTotal> totals =
                transactionRepository.sumByCategory(userId, type, from, to);
        if (totals.isEmpty()) {
            return List.of();
        }
        BigDecimal grand = totals.stream()
                .map(TransactionRepository.CategoryTotal::getTotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Map<UUID, Category> categories = categoryRepository.findByIdIn(
                        totals.stream().map(TransactionRepository.CategoryTotal::getCategoryId).toList())
                .stream().collect(Collectors.toMap(Category::getId, Function.identity()));

        return totals.stream().map(t -> {
            Category c = categories.get(t.getCategoryId());
            double percentage = grand.signum() == 0 ? 0.0
                    : t.getTotal().multiply(BigDecimal.valueOf(100))
                        .divide(grand, 1, RoundingMode.HALF_UP).doubleValue();
            return new CategoryBreakdownResponse(
                    t.getCategoryId(),
                    c == null ? "—" : c.getName(),
                    c == null ? null : c.getColor(),
                    t.getTotal(),
                    percentage);
        }).toList();
    }

    @Transactional(readOnly = true)
    public List<TrendPointResponse> trend(UUID userId, LocalDate from, LocalDate to) {
        return transactionRepository.trend(userId, from, to).stream()
                .map(r -> new TrendPointResponse(r.getMonth(), r.getIncome(), r.getExpense()))
                .toList();
    }
}
```

- [ ] **Step 5: Запустить тест — убедиться, что проходит**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test --tests 'com.aifb.platform.finance.statistics.StatisticsServiceIT'
```
Expected: `BUILD SUCCESSFUL`, 4 теста passed.

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/com/aifb/platform/finance/statistics backend/src/test/java/com/aifb/platform/finance/statistics/StatisticsServiceIT.java
git commit -m "feat(statistics): сервис сводки/по категориям/тренда с тестами"
```

---

## Task 3: Статистика — контроллер и web-тесты

**Files:**
- Create: `.../finance/statistics/api/StatisticsController.java`
- Test: `backend/src/test/java/com/aifb/platform/finance/statistics/StatisticsApiIT.java`

- [ ] **Step 1: Написать падающий web-тест**

Create `backend/src/test/java/com/aifb/platform/finance/statistics/StatisticsApiIT.java`:
```java
package com.aifb.platform.finance.statistics;

import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
import com.aifb.platform.finance.transaction.service.TransactionService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class StatisticsApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired CategoryService categoryService;
    @Autowired TransactionService transactionService;

    @Test
    void summaryEndpointReturnsTotals() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        UUID incomeId = categoryService.list(user.id(), CategoryType.INCOME).get(0).id();
        transactionService.create(user.id(), new CreateTransactionRequest(
                incomeId, CategoryType.INCOME, new BigDecimal("900.00"), null, LocalDate.now()));

        mockMvc.perform(get("/api/v1/statistics/summary")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.income").value(900.00))
                .andExpect(jsonPath("$.data.net").value(900.00));
    }

    @Test
    void byCategoryEndpointReturnsArray() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        UUID expenseId = categoryService.list(user.id(), CategoryType.EXPENSE).get(0).id();
        transactionService.create(user.id(), new CreateTransactionRequest(
                expenseId, CategoryType.EXPENSE, new BigDecimal("123.00"), null, LocalDate.now()));

        mockMvc.perform(get("/api/v1/statistics/by-category")
                        .param("type", "EXPENSE")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].total").value(123.00))
                .andExpect(jsonPath("$.data[0].percentage").value(100.0));
    }

    @Test
    void statisticsRequireAuth() throws Exception {
        mockMvc.perform(get("/api/v1/statistics/summary"))
                .andExpect(status().isUnauthorized());
    }
}
```

- [ ] **Step 2: Запустить тест — убедиться, что падает**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test --tests 'com.aifb.platform.finance.statistics.StatisticsApiIT'
```
Expected: FAIL — контроллера нет.

- [ ] **Step 3: Создать `StatisticsController`**

Create `.../finance/statistics/api/StatisticsController.java`:
```java
package com.aifb.platform.finance.statistics.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.statistics.api.dto.CategoryBreakdownResponse;
import com.aifb.platform.finance.statistics.api.dto.SummaryResponse;
import com.aifb.platform.finance.statistics.api.dto.TrendPointResponse;
import com.aifb.platform.finance.statistics.service.StatisticsService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/v1/statistics")
public class StatisticsController {

    private final StatisticsService service;

    public StatisticsController(StatisticsService service) {
        this.service = service;
    }

    @GetMapping("/summary")
    public ApiResponse<SummaryResponse> summary(
            @CurrentUser AuthPrincipal principal,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ApiResponse.ok(service.summary(principal.userId(), from, to));
    }

    @GetMapping("/by-category")
    public ApiResponse<List<CategoryBreakdownResponse>> byCategory(
            @CurrentUser AuthPrincipal principal,
            @RequestParam(defaultValue = "EXPENSE") CategoryType type,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ApiResponse.ok(service.byCategory(principal.userId(), type, from, to));
    }

    @GetMapping("/trend")
    public ApiResponse<List<TrendPointResponse>> trend(
            @CurrentUser AuthPrincipal principal,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ApiResponse.ok(service.trend(principal.userId(), from, to));
    }
}
```

- [ ] **Step 4: Запустить тест — убедиться, что проходит**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test --tests 'com.aifb.platform.finance.statistics.StatisticsApiIT'
```
Expected: `BUILD SUCCESSFUL`, 3 теста passed.

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/com/aifb/platform/finance/statistics/api/StatisticsController.java backend/src/test/java/com/aifb/platform/finance/statistics/StatisticsApiIT.java
git commit -m "feat(statistics): REST-контроллер статистики с web-тестами"
```

---

## Task 4: Цели — миграции, enum, сущности, репозитории

**Files:**
- Create: `backend/src/main/resources/db/migration/V6__goals.sql`
- Create: `backend/src/main/resources/db/migration/V7__goal_contributions.sql`
- Create: `.../finance/goal/domain/GoalStatus.java`
- Create: `.../finance/goal/domain/Goal.java`
- Create: `.../finance/goal/domain/GoalContribution.java`
- Create: `.../finance/goal/repository/GoalRepository.java`
- Create: `.../finance/goal/repository/GoalContributionRepository.java`

- [ ] **Step 1: Создать миграцию V6 (goals)**

Create `backend/src/main/resources/db/migration/V6__goals.sql`:
```sql
CREATE TABLE goals (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(120) NOT NULL,
    target_amount NUMERIC(15,2) NOT NULL,
    deadline DATE,
    status VARCHAR(12) NOT NULL DEFAULT 'ACTIVE',
    icon VARCHAR(40),
    color VARCHAR(9),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT chk_goals_target_positive CHECK (target_amount > 0),
    CONSTRAINT chk_goals_status CHECK (status IN ('ACTIVE', 'COMPLETED', 'ARCHIVED'))
);

CREATE INDEX idx_goals_user ON goals (user_id);
```

- [ ] **Step 2: Создать миграцию V7 (goal_contributions)**

Create `backend/src/main/resources/db/migration/V7__goal_contributions.sql`:
```sql
CREATE TABLE goal_contributions (
    id UUID PRIMARY KEY,
    goal_id UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
    amount NUMERIC(15,2) NOT NULL,
    note VARCHAR(255),
    contributed_on DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT chk_goal_contributions_amount_positive CHECK (amount > 0)
);

CREATE INDEX idx_goal_contributions_goal ON goal_contributions (goal_id, contributed_on DESC);
```

- [ ] **Step 3: Создать enum `GoalStatus`**

Create `.../finance/goal/domain/GoalStatus.java`:
```java
package com.aifb.platform.finance.goal.domain;

public enum GoalStatus {
    ACTIVE,
    COMPLETED,
    ARCHIVED
}
```

- [ ] **Step 4: Создать сущность `Goal`**

Create `.../finance/goal/domain/Goal.java`:
```java
package com.aifb.platform.finance.goal.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "goals")
public class Goal extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(name = "target_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal targetAmount;

    @Column
    private LocalDate deadline;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 12)
    private GoalStatus status;

    @Column(length = 40)
    private String icon;

    @Column(length = 9)
    private String color;

    protected Goal() {
    }

    public Goal(UUID userId, String name, BigDecimal targetAmount,
                LocalDate deadline, String icon, String color) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.name = name;
        this.targetAmount = targetAmount;
        this.deadline = deadline;
        this.icon = icon;
        this.color = color;
        this.status = GoalStatus.ACTIVE;
    }

    public UUID getUserId() { return userId; }
    public String getName() { return name; }
    public BigDecimal getTargetAmount() { return targetAmount; }
    public LocalDate getDeadline() { return deadline; }
    public GoalStatus getStatus() { return status; }
    public String getIcon() { return icon; }
    public String getColor() { return color; }

    public void setName(String name) { this.name = name; }
    public void setTargetAmount(BigDecimal targetAmount) { this.targetAmount = targetAmount; }
    public void setDeadline(LocalDate deadline) { this.deadline = deadline; }
    public void setIcon(String icon) { this.icon = icon; }
    public void setColor(String color) { this.color = color; }
    public void setStatus(GoalStatus status) { this.status = status; }

    /** Пересчитать статус по накопленной сумме (ARCHIVED не трогаем). */
    public void recomputeStatus(BigDecimal savedAmount) {
        if (status == GoalStatus.ARCHIVED) {
            return;
        }
        status = savedAmount.compareTo(targetAmount) >= 0
                ? GoalStatus.COMPLETED
                : GoalStatus.ACTIVE;
    }
}
```

- [ ] **Step 5: Создать сущность `GoalContribution`**

Create `.../finance/goal/domain/GoalContribution.java`:
```java
package com.aifb.platform.finance.goal.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "goal_contributions")
public class GoalContribution extends BaseEntity {

    @Column(name = "goal_id", nullable = false)
    private UUID goalId;

    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal amount;

    @Column(length = 255)
    private String note;

    @Column(name = "contributed_on", nullable = false)
    private LocalDate contributedOn;

    protected GoalContribution() {
    }

    public GoalContribution(UUID goalId, BigDecimal amount, String note, LocalDate contributedOn) {
        this.id = UUID.randomUUID();
        this.goalId = goalId;
        this.amount = amount;
        this.note = note;
        this.contributedOn = contributedOn;
    }

    public UUID getGoalId() { return goalId; }
    public BigDecimal getAmount() { return amount; }
    public String getNote() { return note; }
    public LocalDate getContributedOn() { return contributedOn; }
}
```

- [ ] **Step 6: Создать репозитории**

Create `.../finance/goal/repository/GoalRepository.java`:
```java
package com.aifb.platform.finance.goal.repository;

import com.aifb.platform.finance.goal.domain.Goal;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface GoalRepository extends JpaRepository<Goal, UUID> {
    List<Goal> findByUserIdOrderByCreatedAtDesc(UUID userId);
    Optional<Goal> findByIdAndUserId(UUID id, UUID userId);
}
```

Create `.../finance/goal/repository/GoalContributionRepository.java`:
```java
package com.aifb.platform.finance.goal.repository;

import com.aifb.platform.finance.goal.domain.GoalContribution;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

public interface GoalContributionRepository extends JpaRepository<GoalContribution, UUID> {

    List<GoalContribution> findByGoalIdOrderByContributedOnDesc(UUID goalId);

    Optional<GoalContribution> findByIdAndGoalId(UUID id, UUID goalId);

    @Query("select coalesce(sum(c.amount), 0) from GoalContribution c where c.goalId = :goalId")
    BigDecimal sumByGoalId(@Param("goalId") UUID goalId);

    interface GoalSum {
        UUID getGoalId();
        BigDecimal getTotal();
    }

    @Query("""
            select c.goalId as goalId, coalesce(sum(c.amount), 0) as total
            from GoalContribution c
            where c.goalId in :goalIds
            group by c.goalId
            """)
    List<GoalSum> sumByGoalIds(@Param("goalIds") Collection<UUID> goalIds);
}
```

Add the missing import to `GoalContributionRepository.java` (the editor must include it):
```java
import java.util.Optional;
```

- [ ] **Step 7: Проверить валидацию схемы**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test --tests 'com.aifb.platform.SmokeContextIT'
```
Expected: `BUILD SUCCESSFUL`. Flyway применяет V6/V7, Hibernate `validate` подтверждает соответствие `Goal` и `GoalContribution`.

- [ ] **Step 8: Commit**

```bash
git add backend/src/main/resources/db/migration/V6__goals.sql backend/src/main/resources/db/migration/V7__goal_contributions.sql backend/src/main/java/com/aifb/platform/finance/goal/domain backend/src/main/java/com/aifb/platform/finance/goal/repository
git commit -m "feat(goal): миграции, сущности и репозитории целей и взносов"
```

---

## Task 5: Цели — DTO, сервис, тесты сервиса

**Files:**
- Create: `.../finance/goal/api/dto/GoalResponse.java`
- Create: `.../finance/goal/api/dto/CreateGoalRequest.java`
- Create: `.../finance/goal/api/dto/UpdateGoalRequest.java`
- Create: `.../finance/goal/api/dto/ContributionResponse.java`
- Create: `.../finance/goal/api/dto/CreateContributionRequest.java`
- Create: `.../finance/goal/service/GoalService.java`
- Test: `backend/src/test/java/com/aifb/platform/finance/goal/GoalServiceIT.java`

- [ ] **Step 1: Создать DTO целей**

Create `.../finance/goal/api/dto/GoalResponse.java`:
```java
package com.aifb.platform.finance.goal.api.dto;

import com.aifb.platform.finance.goal.domain.Goal;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.UUID;

public record GoalResponse(
        UUID id,
        String name,
        BigDecimal targetAmount,
        BigDecimal savedAmount,
        double percentage,
        LocalDate deadline,
        String status,
        String icon,
        String color) {

    public static GoalResponse from(Goal g, BigDecimal saved) {
        BigDecimal safeSaved = saved == null ? BigDecimal.ZERO : saved;
        double percentage = g.getTargetAmount().signum() == 0 ? 0.0
                : Math.min(100.0, safeSaved.multiply(BigDecimal.valueOf(100))
                    .divide(g.getTargetAmount(), 1, RoundingMode.HALF_UP).doubleValue());
        return new GoalResponse(
                g.getId(),
                g.getName(),
                g.getTargetAmount(),
                safeSaved,
                percentage,
                g.getDeadline(),
                g.getStatus().name(),
                g.getIcon(),
                g.getColor());
    }
}
```

Create `.../finance/goal/api/dto/CreateGoalRequest.java`:
```java
package com.aifb.platform.finance.goal.api.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;

public record CreateGoalRequest(
        @NotBlank @Size(max = 120) String name,
        @NotNull @DecimalMin(value = "0.01") @Digits(integer = 13, fraction = 2) BigDecimal targetAmount,
        LocalDate deadline,
        @Size(max = 40) String icon,
        @Size(max = 9) String color) {
}
```

Create `.../finance/goal/api/dto/UpdateGoalRequest.java`:
```java
package com.aifb.platform.finance.goal.api.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;

public record UpdateGoalRequest(
        @NotBlank @Size(max = 120) String name,
        @NotNull @DecimalMin(value = "0.01") @Digits(integer = 13, fraction = 2) BigDecimal targetAmount,
        LocalDate deadline,
        @Size(max = 40) String icon,
        @Size(max = 9) String color) {
}
```

Create `.../finance/goal/api/dto/ContributionResponse.java`:
```java
package com.aifb.platform.finance.goal.api.dto;

import com.aifb.platform.finance.goal.domain.GoalContribution;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public record ContributionResponse(
        UUID id,
        UUID goalId,
        BigDecimal amount,
        String note,
        LocalDate contributedOn) {

    public static ContributionResponse from(GoalContribution c) {
        return new ContributionResponse(
                c.getId(), c.getGoalId(), c.getAmount(), c.getNote(), c.getContributedOn());
    }
}
```

Create `.../finance/goal/api/dto/CreateContributionRequest.java`:
```java
package com.aifb.platform.finance.goal.api.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;

public record CreateContributionRequest(
        @NotNull @DecimalMin(value = "0.01") @Digits(integer = 13, fraction = 2) BigDecimal amount,
        @Size(max = 255) String note,
        @NotNull @PastOrPresent LocalDate contributedOn) {
}
```

- [ ] **Step 2: Написать падающий тест сервиса**

Create `backend/src/test/java/com/aifb/platform/finance/goal/GoalServiceIT.java`:
```java
package com.aifb.platform.finance.goal;

import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.goal.api.dto.ContributionResponse;
import com.aifb.platform.finance.goal.api.dto.CreateContributionRequest;
import com.aifb.platform.finance.goal.api.dto.CreateGoalRequest;
import com.aifb.platform.finance.goal.api.dto.GoalResponse;
import com.aifb.platform.finance.goal.api.dto.UpdateGoalRequest;
import com.aifb.platform.finance.goal.service.GoalService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class GoalServiceIT extends AbstractIntegrationTest {

    @Autowired GoalService service;
    @Autowired TestAuth testAuth;

    private GoalResponse newGoal(UUID userId, String target) {
        return service.create(userId, new CreateGoalRequest(
                "Отпуск", new BigDecimal(target), LocalDate.now().plusMonths(6), "beach", "#22AAFF"));
    }

    @Test
    void createStartsActiveWithZeroProgress() {
        UUID userId = testAuth.createUser().id();
        GoalResponse goal = newGoal(userId, "1000.00");
        assertThat(goal.status()).isEqualTo("ACTIVE");
        assertThat(goal.savedAmount()).isEqualByComparingTo("0");
        assertThat(goal.percentage()).isEqualTo(0.0);
    }

    @Test
    void contributionsIncreaseProgress() {
        UUID userId = testAuth.createUser().id();
        GoalResponse goal = newGoal(userId, "1000.00");

        service.addContribution(userId, goal.id(),
                new CreateContributionRequest(new BigDecimal("250.00"), "первый", LocalDate.now()));
        GoalResponse afterFirst = service.get(userId, goal.id());
        assertThat(afterFirst.savedAmount()).isEqualByComparingTo("250.00");
        assertThat(afterFirst.percentage()).isEqualTo(25.0);
        assertThat(afterFirst.status()).isEqualTo("ACTIVE");
    }

    @Test
    void reachingTargetMarksCompleted() {
        UUID userId = testAuth.createUser().id();
        GoalResponse goal = newGoal(userId, "500.00");
        service.addContribution(userId, goal.id(),
                new CreateContributionRequest(new BigDecimal("500.00"), null, LocalDate.now()));
        assertThat(service.get(userId, goal.id()).status()).isEqualTo("COMPLETED");
    }

    @Test
    void deletingContributionRevertsCompletion() {
        UUID userId = testAuth.createUser().id();
        GoalResponse goal = newGoal(userId, "500.00");
        ContributionResponse c = service.addContribution(userId, goal.id(),
                new CreateContributionRequest(new BigDecimal("500.00"), null, LocalDate.now()));
        assertThat(service.get(userId, goal.id()).status()).isEqualTo("COMPLETED");

        service.deleteContribution(userId, goal.id(), c.id());
        GoalResponse after = service.get(userId, goal.id());
        assertThat(after.savedAmount()).isEqualByComparingTo("0");
        assertThat(after.status()).isEqualTo("ACTIVE");
    }

    @Test
    void listReturnsGoalsWithProgress() {
        UUID userId = testAuth.createUser().id();
        GoalResponse goal = newGoal(userId, "1000.00");
        service.addContribution(userId, goal.id(),
                new CreateContributionRequest(new BigDecimal("100.00"), null, LocalDate.now()));
        assertThat(service.list(userId))
                .anyMatch(g -> g.id().equals(goal.id())
                        && g.savedAmount().compareTo(new BigDecimal("100.00")) == 0);
    }

    @Test
    void updateChangesNameAndTarget() {
        UUID userId = testAuth.createUser().id();
        GoalResponse goal = newGoal(userId, "1000.00");
        GoalResponse updated = service.update(userId, goal.id(),
                new UpdateGoalRequest("Машина", new BigDecimal("2000.00"), null, "car", "#FF0000"));
        assertThat(updated.name()).isEqualTo("Машина");
        assertThat(updated.targetAmount()).isEqualByComparingTo("2000.00");
    }

    @Test
    void otherUserCannotAccessGoal() {
        UUID owner = testAuth.createUser().id();
        UUID other = testAuth.createUser().id();
        GoalResponse goal = newGoal(owner, "1000.00");
        assertThatThrownBy(() -> service.get(other, goal.id()))
                .isInstanceOf(NotFoundException.class);
        assertThatThrownBy(() -> service.addContribution(other, goal.id(),
                new CreateContributionRequest(new BigDecimal("10.00"), null, LocalDate.now())))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void deleteRemovesGoalAndContributions() {
        UUID userId = testAuth.createUser().id();
        GoalResponse goal = newGoal(userId, "1000.00");
        service.addContribution(userId, goal.id(),
                new CreateContributionRequest(new BigDecimal("100.00"), null, LocalDate.now()));
        service.delete(userId, goal.id());
        assertThat(service.list(userId)).noneMatch(g -> g.id().equals(goal.id()));
    }
}
```

- [ ] **Step 3: Запустить тест — убедиться, что НЕ компилируется/падает**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test --tests 'com.aifb.platform.finance.goal.GoalServiceIT'
```
Expected: FAIL — `GoalService` ещё не создан.

- [ ] **Step 4: Создать `GoalService`**

Create `.../finance/goal/service/GoalService.java`:
```java
package com.aifb.platform.finance.goal.service;

import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.goal.api.dto.ContributionResponse;
import com.aifb.platform.finance.goal.api.dto.CreateContributionRequest;
import com.aifb.platform.finance.goal.api.dto.CreateGoalRequest;
import com.aifb.platform.finance.goal.api.dto.GoalResponse;
import com.aifb.platform.finance.goal.api.dto.UpdateGoalRequest;
import com.aifb.platform.finance.goal.domain.Goal;
import com.aifb.platform.finance.goal.domain.GoalContribution;
import com.aifb.platform.finance.goal.repository.GoalContributionRepository;
import com.aifb.platform.finance.goal.repository.GoalRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class GoalService {

    private final GoalRepository goalRepository;
    private final GoalContributionRepository contributionRepository;

    public GoalService(GoalRepository goalRepository,
                       GoalContributionRepository contributionRepository) {
        this.goalRepository = goalRepository;
        this.contributionRepository = contributionRepository;
    }

    @Transactional(readOnly = true)
    public List<GoalResponse> list(UUID userId) {
        List<Goal> goals = goalRepository.findByUserIdOrderByCreatedAtDesc(userId);
        if (goals.isEmpty()) {
            return List.of();
        }
        Map<UUID, BigDecimal> sums = contributionRepository.sumByGoalIds(
                        goals.stream().map(Goal::getId).toList())
                .stream().collect(Collectors.toMap(
                        GoalContributionRepository.GoalSum::getGoalId,
                        GoalContributionRepository.GoalSum::getTotal));
        return goals.stream()
                .map(g -> GoalResponse.from(g, sums.getOrDefault(g.getId(), BigDecimal.ZERO)))
                .toList();
    }

    @Transactional(readOnly = true)
    public GoalResponse get(UUID userId, UUID goalId) {
        Goal goal = ownedGoal(userId, goalId);
        return GoalResponse.from(goal, contributionRepository.sumByGoalId(goalId));
    }

    @Transactional
    public GoalResponse create(UUID userId, CreateGoalRequest req) {
        Goal goal = new Goal(userId, req.name(), req.targetAmount(),
                req.deadline(), req.icon(), req.color());
        return GoalResponse.from(goalRepository.save(goal), BigDecimal.ZERO);
    }

    @Transactional
    public GoalResponse update(UUID userId, UUID goalId, UpdateGoalRequest req) {
        Goal goal = ownedGoal(userId, goalId);
        goal.setName(req.name());
        goal.setTargetAmount(req.targetAmount());
        goal.setDeadline(req.deadline());
        goal.setIcon(req.icon());
        goal.setColor(req.color());
        BigDecimal saved = contributionRepository.sumByGoalId(goalId);
        goal.recomputeStatus(saved);
        return GoalResponse.from(goalRepository.save(goal), saved);
    }

    @Transactional
    public void delete(UUID userId, UUID goalId) {
        Goal goal = ownedGoal(userId, goalId);
        goalRepository.delete(goal); // взносы удаляются каскадом (FK ON DELETE CASCADE)
    }

    @Transactional(readOnly = true)
    public List<ContributionResponse> listContributions(UUID userId, UUID goalId) {
        ownedGoal(userId, goalId);
        return contributionRepository.findByGoalIdOrderByContributedOnDesc(goalId).stream()
                .map(ContributionResponse::from)
                .toList();
    }

    @Transactional
    public ContributionResponse addContribution(UUID userId, UUID goalId, CreateContributionRequest req) {
        Goal goal = ownedGoal(userId, goalId);
        GoalContribution contribution = new GoalContribution(
                goalId, req.amount(), req.note(), req.contributedOn());
        contributionRepository.save(contribution);
        goal.recomputeStatus(contributionRepository.sumByGoalId(goalId));
        goalRepository.save(goal);
        return ContributionResponse.from(contribution);
    }

    @Transactional
    public void deleteContribution(UUID userId, UUID goalId, UUID contributionId) {
        Goal goal = ownedGoal(userId, goalId);
        GoalContribution contribution = contributionRepository.findByIdAndGoalId(contributionId, goalId)
                .orElseThrow(() -> new NotFoundException("Взнос не найден"));
        contributionRepository.delete(contribution);
        goal.recomputeStatus(contributionRepository.sumByGoalId(goalId));
        goalRepository.save(goal);
    }

    private Goal ownedGoal(UUID userId, UUID goalId) {
        return goalRepository.findByIdAndUserId(goalId, userId)
                .orElseThrow(() -> new NotFoundException("Цель не найдена"));
    }
}
```

- [ ] **Step 5: Запустить тест — убедиться, что проходит**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test --tests 'com.aifb.platform.finance.goal.GoalServiceIT'
```
Expected: `BUILD SUCCESSFUL`, 8 тестов passed.

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/com/aifb/platform/finance/goal/api backend/src/main/java/com/aifb/platform/finance/goal/service backend/src/test/java/com/aifb/platform/finance/goal/GoalServiceIT.java
git commit -m "feat(goal): сервис целей и взносов с тестами (прогресс, авто-COMPLETED, изоляция)"
```

---

## Task 6: Цели — контроллер и web-тесты

**Files:**
- Create: `.../finance/goal/api/GoalController.java`
- Test: `backend/src/test/java/com/aifb/platform/finance/goal/GoalApiIT.java`

- [ ] **Step 1: Написать падающий web-тест**

Create `backend/src/test/java/com/aifb/platform/finance/goal/GoalApiIT.java`:
```java
package com.aifb.platform.finance.goal;

import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MvcResult;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class GoalApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired ObjectMapper objectMapper;

    @Test
    void createGoalAddContributionAndReadProgress() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();

        MvcResult created = mockMvc.perform(post("/api/v1/goals")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Подушка","targetAmount":1000.00,"icon":"savings","color":"#00AA66"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("ACTIVE"))
                .andExpect(jsonPath("$.data.savedAmount").value(0))
                .andReturn();

        JsonNode body = objectMapper.readTree(created.getResponse().getContentAsString());
        String goalId = body.path("data").path("id").asText();

        mockMvc.perform(post("/api/v1/goals/" + goalId + "/contributions")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"amount":1000.00,"note":"закрыли","contributedOn":"%s"}
                                """.formatted(java.time.LocalDate.now())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.amount").value(1000.00));

        mockMvc.perform(get("/api/v1/goals/" + goalId)
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.savedAmount").value(1000.00))
                .andExpect(jsonPath("$.data.status").value("COMPLETED"));
    }

    @Test
    void listGoalsRequiresAuth() throws Exception {
        mockMvc.perform(get("/api/v1/goals"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void createRejectsNonPositiveTarget() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        mockMvc.perform(post("/api/v1/goals")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Bad","targetAmount":0}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("VALIDATION_FAILED"));
    }
}
```

- [ ] **Step 2: Запустить тест — убедиться, что падает**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test --tests 'com.aifb.platform.finance.goal.GoalApiIT'
```
Expected: FAIL — контроллера нет.

- [ ] **Step 3: Создать `GoalController`**

Create `.../finance/goal/api/GoalController.java`:
```java
package com.aifb.platform.finance.goal.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.finance.goal.api.dto.ContributionResponse;
import com.aifb.platform.finance.goal.api.dto.CreateContributionRequest;
import com.aifb.platform.finance.goal.api.dto.CreateGoalRequest;
import com.aifb.platform.finance.goal.api.dto.GoalResponse;
import com.aifb.platform.finance.goal.api.dto.UpdateGoalRequest;
import com.aifb.platform.finance.goal.service.GoalService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/goals")
public class GoalController {

    private final GoalService service;

    public GoalController(GoalService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<List<GoalResponse>> list(@CurrentUser AuthPrincipal principal) {
        return ApiResponse.ok(service.list(principal.userId()));
    }

    @GetMapping("/{id}")
    public ApiResponse<GoalResponse> get(@CurrentUser AuthPrincipal principal,
                                         @PathVariable UUID id) {
        return ApiResponse.ok(service.get(principal.userId(), id));
    }

    @PostMapping
    public ApiResponse<GoalResponse> create(@CurrentUser AuthPrincipal principal,
                                            @Valid @RequestBody CreateGoalRequest request) {
        return ApiResponse.ok(service.create(principal.userId(), request));
    }

    @PutMapping("/{id}")
    public ApiResponse<GoalResponse> update(@CurrentUser AuthPrincipal principal,
                                            @PathVariable UUID id,
                                            @Valid @RequestBody UpdateGoalRequest request) {
        return ApiResponse.ok(service.update(principal.userId(), id, request));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@CurrentUser AuthPrincipal principal,
                                    @PathVariable UUID id) {
        service.delete(principal.userId(), id);
        return ApiResponse.ok(null);
    }

    @GetMapping("/{id}/contributions")
    public ApiResponse<List<ContributionResponse>> listContributions(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id) {
        return ApiResponse.ok(service.listContributions(principal.userId(), id));
    }

    @PostMapping("/{id}/contributions")
    public ApiResponse<ContributionResponse> addContribution(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id,
            @Valid @RequestBody CreateContributionRequest request) {
        return ApiResponse.ok(service.addContribution(principal.userId(), id, request));
    }

    @DeleteMapping("/{id}/contributions/{contributionId}")
    public ApiResponse<Void> deleteContribution(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id,
            @PathVariable UUID contributionId) {
        service.deleteContribution(principal.userId(), id, contributionId);
        return ApiResponse.ok(null);
    }
}
```

- [ ] **Step 4: Запустить тест — убедиться, что проходит**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test --tests 'com.aifb.platform.finance.goal.GoalApiIT'
```
Expected: `BUILD SUCCESSFUL`, 3 теста passed.

- [ ] **Step 5: Прогнать весь тестовый набор**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test
```
Expected: `BUILD SUCCESSFUL`, все тесты (План 1 + статистика + цели) passed.

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/com/aifb/platform/finance/goal/api/GoalController.java backend/src/test/java/com/aifb/platform/finance/goal/GoalApiIT.java
git commit -m "feat(goal): REST-контроллер целей и взносов с web-тестами"
```

---

## Self-review (выполнено при написании плана)

- **Покрытие спеки:** статистика (summary / by-category / trend) и цели (CRUD + взносы, прогресс, авто-`COMPLETED`) — секции спеки «REST API → Статистика/Цели» и «Модель данных → goals/goal_contributions» реализованы. Соответствует декомпозиции: Frontend — в Плане 3.
- **Плейсхолдеры:** отсутствуют — каждый шаг содержит полный код или точную команду с ожидаемым результатом.
- **Согласованность типов:** проекции `TransactionRepository.TypeTotal/CategoryTotal/TrendRow` и `GoalContributionRepository.GoalSum` используются в `StatisticsService`/`GoalService` с совпадающими именами геттеров. `GoalResponse.from(Goal, BigDecimal)`, `ContributionResponse.from(GoalContribution)`, `Goal.recomputeStatus(BigDecimal)` вызываются ровно так, как объявлены. Имена параметров запросов (`from`/`to`/`type`/`categoryId`) совпадают между репозиторием, сервисом и контроллером.
- **Нативный тренд-запрос:** `cast(:from as date)`-guard корректно обрабатывает NULL-параметры в Postgres; `to_char(occurred_on,'YYYY-MM')` даёт формат `YYYY-MM`, проверяемый тестом регуляркой.
- **Каскад взносов:** удаление цели опирается на FK `ON DELETE CASCADE` (V7) — отдельной чистки взносов в коде не требуется.
