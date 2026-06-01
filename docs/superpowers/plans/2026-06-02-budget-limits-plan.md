# План — Лимиты и бюджетирование

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Месячные лимиты на EXPENSE-категорию/группу: CRUD, расчёт «потрачено за текущий месяц», статусы OK/WARNING/EXCEEDED с прогрессом, мягкое предупреждение в ответе на создание операции; scope-aware, права OWNER/ADULT на семейные.

**Architecture:** Новый модуль `finance/budget`. Сущность `BudgetLimit` (цель — категория ИЛИ группа, дискриминатор `household_id`). «Потрачено» — отдельный read-репозиторий над `Transaction` (суммы EXPENSE за переданный период `[from,to]`, scope-aware; границы месяца вычисляются в Java, не в SQL). Права/scope — через `HouseholdContextService`. `TransactionService` при создании EXPENSE-операции зовёт `BudgetService` за предупреждениями (однонаправленная зависимость transaction→budget).

**Tech Stack:** Spring Boot 3.3.5, Java 21, Spring Data JPA, PostgreSQL, Flyway; Flutter 3.44 (Riverpod/Dio); тесты — Testcontainers + MockMvc + mocktail.

**Предусловие:** ветка `feature/budget-limits` (от `feature/category-groups`). Группы (V10, `categories.group_id`, `CategoryGroupRepository`), семейный бюджет (`HouseholdContextService`, scope), категории (`CategoryRepository.findVisibleByIdPersonal/Family`) реализованы.

---

## Структура файлов

**Backend создаваемые:**
- `backend/src/main/resources/db/migration/V11__budget_limits.sql`
- `finance/budget/domain/{BudgetTargetType,BudgetStatus,BudgetLimit}.java`
- `finance/budget/repository/{BudgetLimitRepository,BudgetSpendingRepository}.java`
- `finance/budget/service/BudgetService.java`
- `finance/budget/api/BudgetController.java`
- `finance/budget/api/dto/{BudgetResponse,CreateBudgetRequest,UpdateBudgetRequest,BudgetWarning}.java`

**Backend изменяемые:**
- `finance/transaction/api/dto/TransactionResponse.java` (+ `budgetWarnings`)
- `finance/transaction/service/TransactionService.java` (предупреждения при create)

**Frontend создаваемые:** `features/budgets/data/models/{budget_model,budget_warning_model}.dart`, `.../data/budgets_data_source.dart`, `.../data/budgets_repository.dart`, `.../presentation/providers/budgets_providers.dart`, `.../presentation/pages/budgets_page.dart`, `test/features/budgets/budgets_repository_test.dart`; route; `+budgetWarnings` в `TransactionModel`; SnackBar в форме операции.

**Тесты backend:** `finance/budget/BudgetServiceIT.java`, `BudgetApiIT.java`, `finance/transaction/BudgetWarningIT.java`.

Команды backend — из `backend/`, `JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home`; Docker запущен. Frontend — из `frontend/`.

---

## Task 1: Миграция V11, enum'ы, сущность, репозитории

**Files:** V11 sql; `BudgetTargetType.java`; `BudgetStatus.java`; `BudgetLimit.java`; `BudgetLimitRepository.java`; `BudgetSpendingRepository.java`.

- [ ] **Step 1: Миграция** `backend/src/main/resources/db/migration/V11__budget_limits.sql`:
```sql
CREATE TABLE budget_limits (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    household_id UUID REFERENCES households(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    group_id UUID REFERENCES category_groups(id) ON DELETE CASCADE,
    amount NUMERIC(15,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT chk_budget_limits_amount_positive CHECK (amount > 0),
    CONSTRAINT chk_budget_limits_one_target CHECK ((category_id IS NULL) <> (group_id IS NULL))
);

CREATE UNIQUE INDEX uk_budget_limits_category ON budget_limits (category_id) WHERE category_id IS NOT NULL;
CREATE UNIQUE INDEX uk_budget_limits_group ON budget_limits (group_id) WHERE group_id IS NOT NULL;
CREATE INDEX idx_budget_limits_user ON budget_limits (user_id) WHERE household_id IS NULL;
CREATE INDEX idx_budget_limits_household ON budget_limits (household_id) WHERE household_id IS NOT NULL;
```

- [ ] **Step 2: Enum'ы.**
`finance/budget/domain/BudgetTargetType.java`:
```java
package com.aifb.platform.finance.budget.domain;

public enum BudgetTargetType {
    CATEGORY,
    GROUP
}
```
`finance/budget/domain/BudgetStatus.java`:
```java
package com.aifb.platform.finance.budget.domain;

import java.math.BigDecimal;

public enum BudgetStatus {
    OK,
    WARNING,
    EXCEEDED;

    /** spent/limit: <80% OK, 80–100% WARNING, >100% EXCEEDED. limit>0 гарантирован. */
    public static BudgetStatus of(BigDecimal spent, BigDecimal limit) {
        double ratio = spent.doubleValue() / limit.doubleValue();
        if (ratio > 1.0) {
            return EXCEEDED;
        }
        if (ratio >= 0.8) {
            return WARNING;
        }
        return OK;
    }
}
```

- [ ] **Step 3: Сущность** `finance/budget/domain/BudgetLimit.java`:
```java
package com.aifb.platform.finance.budget.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "budget_limits")
public class BudgetLimit extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "household_id")
    private UUID householdId;

    @Column(name = "category_id")
    private UUID categoryId;

    @Column(name = "group_id")
    private UUID groupId;

    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal amount;

    protected BudgetLimit() {
    }

    public BudgetLimit(UUID userId, UUID categoryId, UUID groupId, BigDecimal amount) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.categoryId = categoryId;
        this.groupId = groupId;
        this.amount = amount;
    }

    public UUID getUserId() { return userId; }
    public UUID getHouseholdId() { return householdId; }
    public boolean isShared() { return householdId != null; }
    public UUID getCategoryId() { return categoryId; }
    public UUID getGroupId() { return groupId; }
    public BigDecimal getAmount() { return amount; }
    public BudgetTargetType getTargetType() {
        return categoryId != null ? BudgetTargetType.CATEGORY : BudgetTargetType.GROUP;
    }

    public void assignHousehold(UUID householdId) { this.householdId = householdId; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
}
```

- [ ] **Step 4: Репозиторий лимитов** `finance/budget/repository/BudgetLimitRepository.java`:
```java
package com.aifb.platform.finance.budget.repository;

import com.aifb.platform.finance.budget.domain.BudgetLimit;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BudgetLimitRepository extends JpaRepository<BudgetLimit, UUID> {
    List<BudgetLimit> findByUserIdAndHouseholdIdIsNull(UUID userId);
    List<BudgetLimit> findByHouseholdId(UUID householdId);
    Optional<BudgetLimit> findByCategoryId(UUID categoryId);
    Optional<BudgetLimit> findByGroupId(UUID groupId);
}
```

- [ ] **Step 5: Репозиторий расходов** `finance/budget/repository/BudgetSpendingRepository.java`:
```java
package com.aifb.platform.finance.budget.repository;

import com.aifb.platform.finance.transaction.domain.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/** Read-only суммы EXPENSE для расчёта «потрачено» по лимитам. */
public interface BudgetSpendingRepository extends JpaRepository<Transaction, UUID> {

    @Query("""
            select coalesce(sum(t.amount), 0) from Transaction t
            where t.categoryId = :categoryId
              and t.type = com.aifb.platform.finance.category.domain.CategoryType.EXPENSE
              and ((:householdId is null and t.userId = :userId and t.householdId is null)
                   or (:householdId is not null and t.householdId = :householdId))
              and t.occurredOn between :from and :to
            """)
    BigDecimal sumExpenseForCategory(@Param("userId") UUID userId,
                                     @Param("householdId") UUID householdId,
                                     @Param("categoryId") UUID categoryId,
                                     @Param("from") LocalDate from,
                                     @Param("to") LocalDate to);

    @Query("""
            select coalesce(sum(t.amount), 0)
            from Transaction t, com.aifb.platform.finance.category.domain.Category c
            where t.categoryId = c.id and c.groupId = :groupId
              and t.type = com.aifb.platform.finance.category.domain.CategoryType.EXPENSE
              and ((:householdId is null and t.userId = :userId and t.householdId is null)
                   or (:householdId is not null and t.householdId = :householdId))
              and t.occurredOn between :from and :to
            """)
    BigDecimal sumExpenseForGroup(@Param("userId") UUID userId,
                                  @Param("householdId") UUID householdId,
                                  @Param("groupId") UUID groupId,
                                  @Param("from") LocalDate from,
                                  @Param("to") LocalDate to);
}
```

- [ ] **Step 6: Проверить схему**
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.SmokeContextIT'
```
Expected: BUILD SUCCESSFUL (V11 применена, validate подтверждает `BudgetLimit`).

- [ ] **Step 7: Commit**
```bash
git add backend/src/main/resources/db/migration/V11__budget_limits.sql backend/src/main/java/com/aifb/platform/finance/budget/domain backend/src/main/java/com/aifb/platform/finance/budget/repository
git commit -m "feat(budget): миграция V11, сущность BudgetLimit, репозитории лимитов и расходов"
```

---

## Task 2: DTO, BudgetService (CRUD + расчёт), тесты

**Files:** budget dto x4; `BudgetService.java`; test `BudgetServiceIT.java`.

- [ ] **Step 1: DTO.**
`finance/budget/api/dto/BudgetResponse.java`:
```java
package com.aifb.platform.finance.budget.api.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record BudgetResponse(
        UUID id,
        String targetType,
        UUID targetId,
        String targetName,
        BigDecimal amount,
        BigDecimal spent,
        double percentage,
        String status,
        boolean shared) {
}
```
`finance/budget/api/dto/CreateBudgetRequest.java`:
```java
package com.aifb.platform.finance.budget.api.dto;

import com.aifb.platform.finance.budget.domain.BudgetTargetType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.UUID;

public record CreateBudgetRequest(
        @NotNull BudgetTargetType targetType,
        UUID categoryId,
        UUID groupId,
        @NotNull @DecimalMin(value = "0.01") @Digits(integer = 13, fraction = 2) BigDecimal amount,
        boolean shared) {
}
```
`finance/budget/api/dto/UpdateBudgetRequest.java`:
```java
package com.aifb.platform.finance.budget.api.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record UpdateBudgetRequest(
        @NotNull @DecimalMin(value = "0.01") @Digits(integer = 13, fraction = 2) BigDecimal amount) {
}
```
`finance/budget/api/dto/BudgetWarning.java`:
```java
package com.aifb.platform.finance.budget.api.dto;

import java.math.BigDecimal;

public record BudgetWarning(
        String targetType,
        String targetName,
        BigDecimal amount,
        BigDecimal spent,
        double percentage,
        String status) {
}
```

- [ ] **Step 2: Падающий тест** `backend/src/test/java/com/aifb/platform/finance/budget/BudgetServiceIT.java`:
```java
package com.aifb.platform.finance.budget;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.finance.budget.api.dto.BudgetResponse;
import com.aifb.platform.finance.budget.api.dto.CreateBudgetRequest;
import com.aifb.platform.finance.budget.domain.BudgetTargetType;
import com.aifb.platform.finance.budget.service.BudgetService;
import com.aifb.platform.finance.category.api.dto.CategoryResponse;
import com.aifb.platform.finance.category.api.dto.CreateCategoryRequest;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
import com.aifb.platform.finance.transaction.service.TransactionService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class BudgetServiceIT extends AbstractIntegrationTest {

    @Autowired BudgetService service;
    @Autowired CategoryService categoryService;
    @Autowired TransactionService transactionService;
    @Autowired TestAuth testAuth;

    private UUID expenseCat(UUID userId) {
        return categoryService.list(userId, CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
    }

    @Test
    void createCategoryBudgetAndComputeSpentStatus() {
        UUID userId = testAuth.createUser().id();
        UUID cat = expenseCat(userId);
        BudgetResponse b = service.create(userId, new CreateBudgetRequest(
                BudgetTargetType.CATEGORY, cat, null, new BigDecimal("1000.00"), false));
        assertThat(b.spent()).isEqualByComparingTo("0");
        assertThat(b.status()).isEqualTo("OK");

        // трата 850 в этом месяце → WARNING (85%)
        transactionService.create(userId, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("850.00"), null, LocalDate.now(), false));
        BudgetResponse after = service.list(userId, Scope.PERSONAL).stream()
                .filter(x -> x.id().equals(b.id())).findFirst().orElseThrow();
        assertThat(after.spent()).isEqualByComparingTo("850.00");
        assertThat(after.percentage()).isEqualTo(85.0);
        assertThat(after.status()).isEqualTo("WARNING");
    }

    @Test
    void exceededStatusOverLimit() {
        UUID userId = testAuth.createUser().id();
        UUID cat = expenseCat(userId);
        BudgetResponse b = service.create(userId, new CreateBudgetRequest(
                BudgetTargetType.CATEGORY, cat, null, new BigDecimal("100.00"), false));
        transactionService.create(userId, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("150.00"), null, LocalDate.now(), false));
        BudgetResponse after = service.list(userId, Scope.PERSONAL).stream()
                .filter(x -> x.id().equals(b.id())).findFirst().orElseThrow();
        assertThat(after.status()).isEqualTo("EXCEEDED");
    }

    @Test
    void duplicateBudgetForCategoryConflicts() {
        UUID userId = testAuth.createUser().id();
        UUID cat = expenseCat(userId);
        service.create(userId, new CreateBudgetRequest(
                BudgetTargetType.CATEGORY, cat, null, new BigDecimal("100.00"), false));
        assertThatThrownBy(() -> service.create(userId, new CreateBudgetRequest(
                BudgetTargetType.CATEGORY, cat, null, new BigDecimal("200.00"), false)))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void incomeCategoryRejected() {
        UUID userId = testAuth.createUser().id();
        UUID incomeCat = categoryService.list(userId, CategoryType.INCOME, Scope.PERSONAL).get(0).id();
        assertThatThrownBy(() -> service.create(userId, new CreateBudgetRequest(
                BudgetTargetType.CATEGORY, incomeCat, null, new BigDecimal("100.00"), false)))
                .isInstanceOf(DomainException.class);
    }

    @Test
    void deleteRemovesBudget() {
        UUID userId = testAuth.createUser().id();
        UUID cat = expenseCat(userId);
        BudgetResponse b = service.create(userId, new CreateBudgetRequest(
                BudgetTargetType.CATEGORY, cat, null, new BigDecimal("100.00"), false));
        service.delete(userId, b.id());
        assertThat(service.list(userId, Scope.PERSONAL)).noneMatch(x -> x.id().equals(b.id()));
    }
}
```
Run `... --tests 'com.aifb.platform.finance.budget.BudgetServiceIT'` → FAIL.

- [ ] **Step 3: Сервис** `finance/budget/service/BudgetService.java`:
```java
package com.aifb.platform.finance.budget.service;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.common.exception.ErrorCode;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.budget.api.dto.BudgetResponse;
import com.aifb.platform.finance.budget.api.dto.BudgetWarning;
import com.aifb.platform.finance.budget.api.dto.CreateBudgetRequest;
import com.aifb.platform.finance.budget.api.dto.UpdateBudgetRequest;
import com.aifb.platform.finance.budget.domain.BudgetLimit;
import com.aifb.platform.finance.budget.domain.BudgetStatus;
import com.aifb.platform.finance.budget.domain.BudgetTargetType;
import com.aifb.platform.finance.budget.repository.BudgetLimitRepository;
import com.aifb.platform.finance.budget.repository.BudgetSpendingRepository;
import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.repository.CategoryRepository;
import com.aifb.platform.finance.group.domain.CategoryGroup;
import com.aifb.platform.finance.group.repository.CategoryGroupRepository;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class BudgetService {

    private final BudgetLimitRepository repository;
    private final BudgetSpendingRepository spendingRepository;
    private final CategoryRepository categoryRepository;
    private final CategoryGroupRepository groupRepository;
    private final HouseholdContextService householdContext;

    public BudgetService(BudgetLimitRepository repository,
                         BudgetSpendingRepository spendingRepository,
                         CategoryRepository categoryRepository,
                         CategoryGroupRepository groupRepository,
                         HouseholdContextService householdContext) {
        this.repository = repository;
        this.spendingRepository = spendingRepository;
        this.categoryRepository = categoryRepository;
        this.groupRepository = groupRepository;
        this.householdContext = householdContext;
    }

    @Transactional
    public BudgetResponse create(UUID userId, CreateBudgetRequest req) {
        UUID householdId = null;
        if (req.shared()) {
            HouseholdContext ctx = householdContext.requireManageSharedContent(userId);
            householdId = ctx.householdId();
        }
        BudgetLimit limit;
        if (req.targetType() == BudgetTargetType.CATEGORY) {
            if (req.categoryId() == null) {
                throw new DomainException(ErrorCode.VALIDATION_FAILED, "Не указана категория");
            }
            Category category = resolveVisibleCategory(userId, householdId, req.categoryId());
            if (category.getType() != CategoryType.EXPENSE) {
                throw new DomainException(ErrorCode.VALIDATION_FAILED, "Лимит только для расходов");
            }
            if (repository.findByCategoryId(category.getId()).isPresent()) {
                throw new ConflictException("Лимит на эту категорию уже существует");
            }
            limit = new BudgetLimit(userId, category.getId(), null, req.amount());
        } else {
            if (req.groupId() == null) {
                throw new DomainException(ErrorCode.VALIDATION_FAILED, "Не указана группа");
            }
            CategoryGroup group = resolveVisibleGroup(userId, householdId, req.groupId());
            if (group.getType() != CategoryType.EXPENSE) {
                throw new DomainException(ErrorCode.VALIDATION_FAILED, "Лимит только для расходов");
            }
            if (repository.findByGroupId(group.getId()).isPresent()) {
                throw new ConflictException("Лимит на эту группу уже существует");
            }
            limit = new BudgetLimit(userId, null, group.getId(), req.amount());
        }
        if (householdId != null) {
            limit.assignHousehold(householdId);
        }
        return toResponse(repository.save(limit));
    }

    @Transactional(readOnly = true)
    public List<BudgetResponse> list(UUID userId, Scope scope) {
        List<BudgetLimit> limits;
        if (scope == Scope.FAMILY) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            limits = ctx == null ? List.of() : repository.findByHouseholdId(ctx.householdId());
        } else {
            limits = repository.findByUserIdAndHouseholdIdIsNull(userId);
        }
        return limits.stream().map(this::toResponse).toList();
    }

    @Transactional
    public BudgetResponse update(UUID userId, UUID id, UpdateBudgetRequest req) {
        BudgetLimit limit = manageableLimit(userId, id);
        limit.setAmount(req.amount());
        return toResponse(repository.save(limit));
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        repository.delete(manageableLimit(userId, id));
    }

    /** Предупреждения после создания EXPENSE-операции (лимит на категорию + на её группу). */
    @Transactional(readOnly = true)
    public List<BudgetWarning> warningsForExpense(UUID userId, UUID householdId,
                                                  UUID categoryId, UUID groupId) {
        List<BudgetWarning> warnings = new ArrayList<>();
        repository.findByCategoryId(categoryId).ifPresent(limit -> {
            if (sameScope(limit, householdId)) {
                addIfNotOk(warnings, limit);
            }
        });
        if (groupId != null) {
            repository.findByGroupId(groupId).ifPresent(limit -> {
                if (sameScope(limit, householdId)) {
                    addIfNotOk(warnings, limit);
                }
            });
        }
        return warnings;
    }

    // --- helpers ---

    private boolean sameScope(BudgetLimit limit, UUID householdId) {
        return householdId == null ? limit.getHouseholdId() == null
                : householdId.equals(limit.getHouseholdId());
    }

    private void addIfNotOk(List<BudgetWarning> warnings, BudgetLimit limit) {
        BigDecimal spent = spent(limit);
        BudgetStatus status = BudgetStatus.of(spent, limit.getAmount());
        if (status != BudgetStatus.OK) {
            warnings.add(new BudgetWarning(limit.getTargetType().name(), targetName(limit),
                    limit.getAmount(), spent, percentage(spent, limit.getAmount()), status.name()));
        }
    }

    private Category resolveVisibleCategory(UUID userId, UUID householdId, UUID categoryId) {
        return (householdId == null
                ? categoryRepository.findVisibleByIdPersonal(categoryId, userId)
                : categoryRepository.findVisibleByIdFamily(categoryId, householdId))
                .orElseThrow(() -> new NotFoundException("Категория не найдена"));
    }

    private CategoryGroup resolveVisibleGroup(UUID userId, UUID householdId, UUID groupId) {
        return (householdId == null
                ? groupRepository.findByIdAndUserIdAndHouseholdIdIsNull(groupId, userId)
                : groupRepository.findByIdAndHouseholdId(groupId, householdId))
                .orElseThrow(() -> new NotFoundException("Группа не найдена"));
    }

    private BudgetLimit manageableLimit(UUID userId, UUID id) {
        BudgetLimit limit = repository.findById(id)
                .orElseThrow(() -> new NotFoundException("Лимит не найден"));
        if (limit.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null || !ctx.householdId().equals(limit.getHouseholdId())) {
                throw new NotFoundException("Лимит не найден");
            }
            if (!ctx.canManageSharedContent()) {
                throw new ForbiddenException("Недостаточно прав для семейного лимита");
            }
            return limit;
        }
        if (!userId.equals(limit.getUserId())) {
            throw new NotFoundException("Лимит не найден");
        }
        return limit;
    }

    private BigDecimal spent(BudgetLimit limit) {
        LocalDate today = LocalDate.now();
        LocalDate from = today.withDayOfMonth(1);
        if (limit.getTargetType() == BudgetTargetType.CATEGORY) {
            return spendingRepository.sumExpenseForCategory(
                    limit.getUserId(), limit.getHouseholdId(), limit.getCategoryId(), from, today);
        }
        return spendingRepository.sumExpenseForGroup(
                limit.getUserId(), limit.getHouseholdId(), limit.getGroupId(), from, today);
    }

    private String targetName(BudgetLimit limit) {
        if (limit.getTargetType() == BudgetTargetType.CATEGORY) {
            return categoryRepository.findById(limit.getCategoryId())
                    .map(Category::getName).orElse("—");
        }
        return groupRepository.findById(limit.getGroupId())
                .map(CategoryGroup::getName).orElse("—");
    }

    private double percentage(BigDecimal spent, BigDecimal limit) {
        return spent.multiply(BigDecimal.valueOf(100))
                .divide(limit, 1, RoundingMode.HALF_UP).doubleValue();
    }

    private BudgetResponse toResponse(BudgetLimit limit) {
        BigDecimal spent = spent(limit);
        UUID targetId = limit.getTargetType() == BudgetTargetType.CATEGORY
                ? limit.getCategoryId() : limit.getGroupId();
        return new BudgetResponse(
                limit.getId(), limit.getTargetType().name(), targetId, targetName(limit),
                limit.getAmount(), spent, percentage(spent, limit.getAmount()),
                BudgetStatus.of(spent, limit.getAmount()).name(), limit.isShared());
    }
}
```

- [ ] **Step 4: Run** `... --tests 'com.aifb.platform.finance.budget.BudgetServiceIT'` → BUILD SUCCESSFUL, 5 tests.

- [ ] **Step 5: Commit**
```bash
git add backend/src/main/java/com/aifb/platform/finance/budget/api/dto backend/src/main/java/com/aifb/platform/finance/budget/service backend/src/test/java/com/aifb/platform/finance/budget/BudgetServiceIT.java
git commit -m "feat(budget): сервис лимитов (CRUD, расчёт spent/status, scope, права) с тестами"
```

---

## Task 3: Контроллер бюджетов + web-тесты

**Files:** `BudgetController.java`; test `BudgetApiIT.java`.

- [ ] **Step 1: Падающий web-тест** `backend/src/test/java/com/aifb/platform/finance/budget/BudgetApiIT.java`:
```java
package com.aifb.platform.finance.budget;

import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;

import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class BudgetApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired CategoryService categoryService;

    @Test
    void listRequiresAuth() throws Exception {
        mockMvc.perform(get("/api/v1/budgets"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void createAndListBudget() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        UUID cat = categoryService.list(user.id(), CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
        mockMvc.perform(post("/api/v1/budgets")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"targetType\":\"CATEGORY\",\"categoryId\":\"" + cat + "\",\"amount\":1000.00}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("OK"))
                .andExpect(jsonPath("$.data.spent").value(0));

        mockMvc.perform(get("/api/v1/budgets").param("scope", "PERSONAL")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1));
    }

    @Test
    void createRejectsNonPositiveAmount() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        UUID cat = categoryService.list(user.id(), CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
        mockMvc.perform(post("/api/v1/budgets")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"targetType\":\"CATEGORY\",\"categoryId\":\"" + cat + "\",\"amount\":0}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("VALIDATION_FAILED"));
    }
}
```
Run → FAIL.

- [ ] **Step 2: Контроллер** `finance/budget/api/BudgetController.java`:
```java
package com.aifb.platform.finance.budget.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.finance.budget.api.dto.BudgetResponse;
import com.aifb.platform.finance.budget.api.dto.CreateBudgetRequest;
import com.aifb.platform.finance.budget.api.dto.UpdateBudgetRequest;
import com.aifb.platform.finance.budget.service.BudgetService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/budgets")
public class BudgetController {

    private final BudgetService service;

    public BudgetController(BudgetService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<List<BudgetResponse>> list(
            @CurrentUser AuthPrincipal principal,
            @RequestParam(defaultValue = "PERSONAL") Scope scope) {
        return ApiResponse.ok(service.list(principal.userId(), scope));
    }

    @PostMapping
    public ApiResponse<BudgetResponse> create(
            @CurrentUser AuthPrincipal principal,
            @Valid @RequestBody CreateBudgetRequest request) {
        return ApiResponse.ok(service.create(principal.userId(), request));
    }

    @PutMapping("/{id}")
    public ApiResponse<BudgetResponse> update(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id,
            @Valid @RequestBody UpdateBudgetRequest request) {
        return ApiResponse.ok(service.update(principal.userId(), id, request));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id) {
        service.delete(principal.userId(), id);
        return ApiResponse.ok(null);
    }
}
```

- [ ] **Step 3: Run** `... --tests 'com.aifb.platform.finance.budget.BudgetApiIT'` → BUILD SUCCESSFUL, 3 tests.

- [ ] **Step 4: Commit**
```bash
git add backend/src/main/java/com/aifb/platform/finance/budget/api/BudgetController.java backend/src/test/java/com/aifb/platform/finance/budget/BudgetApiIT.java
git commit -m "feat(budget): REST-контроллер лимитов с web-тестами"
```

---

## Task 4: Предупреждение при создании операции

**Files:** modify `TransactionResponse.java`, `TransactionService.java`; test `finance/transaction/BudgetWarningIT.java`.

- [ ] **Step 1: `TransactionResponse` — добавить `budgetWarnings`.** Replace file:
```java
package com.aifb.platform.finance.transaction.api.dto;

import com.aifb.platform.finance.budget.api.dto.BudgetWarning;
import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.transaction.domain.Transaction;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public record TransactionResponse(
        UUID id, UUID categoryId, String categoryName, String categoryColor,
        String categoryIcon, String type, BigDecimal amount, String note,
        LocalDate occurredOn, Instant createdAt, boolean shared, UUID authorId,
        List<BudgetWarning> budgetWarnings) {

    public static TransactionResponse from(Transaction t, Category category) {
        return from(t, category, null);
    }

    public static TransactionResponse from(Transaction t, Category category,
                                           List<BudgetWarning> budgetWarnings) {
        return new TransactionResponse(
                t.getId(), t.getCategoryId(),
                category == null ? null : category.getName(),
                category == null ? null : category.getColor(),
                category == null ? null : category.getIcon(),
                t.getType().name(), t.getAmount(), t.getNote(),
                t.getOccurredOn(), t.getCreatedAt(), t.isShared(), t.getUserId(),
                budgetWarnings == null || budgetWarnings.isEmpty() ? null : budgetWarnings);
    }
}
```
(`non_null` inclusion: `budgetWarnings` сериализуется только при create с непустым списком.)

- [ ] **Step 2: Падающий тест** `backend/src/test/java/com/aifb/platform/finance/transaction/BudgetWarningIT.java`:
```java
package com.aifb.platform.finance.transaction;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.finance.budget.api.dto.CreateBudgetRequest;
import com.aifb.platform.finance.budget.domain.BudgetTargetType;
import com.aifb.platform.finance.budget.service.BudgetService;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
import com.aifb.platform.finance.transaction.api.dto.TransactionResponse;
import com.aifb.platform.finance.transaction.service.TransactionService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class BudgetWarningIT extends AbstractIntegrationTest {

    @Autowired TransactionService transactionService;
    @Autowired BudgetService budgetService;
    @Autowired CategoryService categoryService;
    @Autowired TestAuth testAuth;

    @Test
    void exceedingBudgetReturnsWarningOnCreate() {
        UUID userId = testAuth.createUser().id();
        UUID cat = categoryService.list(userId, CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
        budgetService.create(userId, new CreateBudgetRequest(
                BudgetTargetType.CATEGORY, cat, null, new BigDecimal("100.00"), false));

        TransactionResponse tx = transactionService.create(userId, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("150.00"), null, LocalDate.now(), false));
        assertThat(tx.budgetWarnings()).isNotNull().hasSize(1);
        assertThat(tx.budgetWarnings().get(0).status()).isEqualTo("EXCEEDED");
    }

    @Test
    void withinBudgetNoWarning() {
        UUID userId = testAuth.createUser().id();
        UUID cat = categoryService.list(userId, CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
        budgetService.create(userId, new CreateBudgetRequest(
                BudgetTargetType.CATEGORY, cat, null, new BigDecimal("1000.00"), false));
        TransactionResponse tx = transactionService.create(userId, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("10.00"), null, LocalDate.now(), false));
        assertThat(tx.budgetWarnings()).isNull();
    }
}
```
Run → FAIL.

- [ ] **Step 3: Обновить `TransactionService`.** Inject `BudgetService budgetService` (constructor param + field). In `create`, change both branches' final return so that for EXPENSE transactions warnings are attached. Replace the two `return TransactionResponse.from(repository.save(t), category);` lines in `create` with a saved+warnings path. Concretely, restructure `create` to:
```java
    @Transactional
    public TransactionResponse create(UUID userId, CreateTransactionRequest req) {
        Category category;
        Transaction t;
        if (req.shared()) {
            HouseholdContext ctx = householdContext.requireMembership(userId);
            category = categoryRepository.findVisibleByIdFamily(req.categoryId(), ctx.householdId())
                    .orElseThrow(() -> new NotFoundException("Категория не найдена"));
            validateType(category, req.type());
            t = new Transaction(userId, category.getId(), req.type(),
                    req.amount(), req.note(), req.occurredOn());
            t.assignHousehold(ctx.householdId());
        } else {
            category = categoryRepository.findVisibleByIdPersonal(req.categoryId(), userId)
                    .orElseThrow(() -> new NotFoundException("Категория не найдена"));
            validateType(category, req.type());
            t = new Transaction(userId, category.getId(), req.type(),
                    req.amount(), req.note(), req.occurredOn());
        }
        Transaction saved = repository.save(t);
        List<BudgetWarning> warnings = req.type() == CategoryType.EXPENSE
                ? budgetService.warningsForExpense(userId, saved.getHouseholdId(),
                        saved.getCategoryId(), category.getGroupId())
                : List.of();
        return TransactionResponse.from(saved, category, warnings);
    }
```
Add imports: `com.aifb.platform.finance.budget.api.dto.BudgetWarning`, `com.aifb.platform.finance.budget.service.BudgetService` (`List`, `CategoryType` already imported). `Category.getGroupId()` exists (groups feature).

- [ ] **Step 4: Run** `... --tests 'com.aifb.platform.finance.transaction.BudgetWarningIT'` → BUILD SUCCESSFUL, 2 tests. (Existing transaction tests unaffected: `from(t, category)` 2-arg still exists; create now returns warnings=null when none.)

- [ ] **Step 5: Full backend suite + commit**
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test
git add backend/src/main/java/com/aifb/platform/finance/transaction backend/src/test/java/com/aifb/platform/finance/transaction/BudgetWarningIT.java
git commit -m "feat(budget): мягкое предупреждение о превышении в ответе на создание операции"
```
Report total backend test count.

---

## Task 5: Frontend — фича budgets + предупреждение в форме

**Files:** budget model/warning model/data source/repo/providers/page; `TransactionModel.budgetWarnings`; route; transaction form SnackBar; test.

- [ ] **Step 1: Endpoint + models.**
In `lib/core/network/api_endpoints.dart` add: `static const String budgets = '/budgets';`
Create `lib/features/budgets/data/models/budget_warning_model.dart`:
```dart
class BudgetWarningModel {
  const BudgetWarningModel({
    required this.targetType,
    required this.targetName,
    required this.amount,
    required this.spent,
    required this.percentage,
    required this.status,
  });

  factory BudgetWarningModel.fromJson(Map<String, dynamic> json) => BudgetWarningModel(
        targetType: json['targetType'] as String,
        targetName: json['targetName'] as String,
        amount: (json['amount'] as num).toDouble(),
        spent: (json['spent'] as num).toDouble(),
        percentage: (json['percentage'] as num).toDouble(),
        status: json['status'] as String,
      );

  final String targetType;
  final String targetName;
  final double amount;
  final double spent;
  final double percentage;
  final String status;
}
```
Create `lib/features/budgets/data/models/budget_model.dart`:
```dart
class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.amount,
    required this.spent,
    required this.percentage,
    required this.status,
    required this.shared,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'] as String,
        targetType: json['targetType'] as String,
        targetId: json['targetId'] as String,
        targetName: json['targetName'] as String,
        amount: (json['amount'] as num).toDouble(),
        spent: (json['spent'] as num).toDouble(),
        percentage: (json['percentage'] as num).toDouble(),
        status: json['status'] as String,
        shared: json['shared'] as bool? ?? false,
      );

  final String id;
  final String targetType;
  final String targetId;
  final String targetName;
  final double amount;
  final double spent;
  final double percentage;
  final String status;
  final bool shared;
}
```
Add to `lib/features/transactions/data/models/transaction_model.dart`: import the warning model (`package:aifb/features/budgets/data/models/budget_warning_model.dart`); add field `final List<BudgetWarningModel> budgetWarnings;`; constructor param `this.budgetWarnings = const []`; in `fromJson`:
```dart
        budgetWarnings: (json['budgetWarnings'] as List?)
                ?.map((e) => BudgetWarningModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
```

- [ ] **Step 2: Data source** `lib/features/budgets/data/budgets_data_source.dart`:
```dart
import 'package:aifb/core/network/api_endpoints.dart';
import 'package:aifb/core/network/envelope.dart';
import 'package:aifb/features/budgets/data/models/budget_model.dart';
import 'package:dio/dio.dart';

class BudgetsDataSource {
  BudgetsDataSource(this._dio);
  final Dio _dio;

  Future<List<BudgetModel>> list({String scope = 'PERSONAL'}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.budgets,
      queryParameters: {'scope': scope},
    );
    return unwrapList(res.data)
        .map((e) => BudgetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BudgetModel> create(Map<String, dynamic> body) async {
    final res =
        await _dio.post<Map<String, dynamic>>(ApiEndpoints.budgets, data: body);
    return BudgetModel.fromJson(unwrapObject(res.data));
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('${ApiEndpoints.budgets}/$id');
  }
}
```

- [ ] **Step 3: Failing repo test** `test/features/budgets/budgets_repository_test.dart`:
```dart
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/budgets/data/budgets_data_source.dart';
import 'package:aifb/features/budgets/data/budgets_repository.dart';
import 'package:aifb/features/budgets/data/models/budget_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDs extends Mock implements BudgetsDataSource {}

void main() {
  late _MockDs ds;
  late BudgetsRepository repo;

  setUp(() {
    ds = _MockDs();
    repo = BudgetsRepository(ds);
  });

  test('list returns Ok with budgets', () async {
    when(() => ds.list(scope: 'PERSONAL')).thenAnswer((_) async => const [
          BudgetModel(
            id: 'b1', targetType: 'CATEGORY', targetId: 'c1', targetName: 'Еда',
            amount: 1000, spent: 850, percentage: 85, status: 'WARNING', shared: false,
          ),
        ]);
    final result = await repo.list();
    expect(result, isA<Ok<List<BudgetModel>>>());
    expect((result as Ok<List<BudgetModel>>).value.single.status, 'WARNING');
  });

  test('list maps error to Err', () async {
    when(() => ds.list(scope: any(named: 'scope'))).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/budgets')),
    );
    final result = await repo.list();
    expect(result, isA<Err<List<BudgetModel>>>());
  });
}
```
Run `cd frontend && flutter test test/features/budgets/budgets_repository_test.dart` → FAIL.

- [ ] **Step 4: Repository** `lib/features/budgets/data/budgets_repository.dart`:
```dart
import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/core/errors/error_mapper.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/budgets/data/budgets_data_source.dart';
import 'package:aifb/features/budgets/data/models/budget_model.dart';

class BudgetsRepository {
  BudgetsRepository(this._ds);
  final BudgetsDataSource _ds;

  Future<Result<List<BudgetModel>>> list({Scope scope = Scope.personal}) =>
      _guard(() => _ds.list(scope: scope.query));

  Future<Result<BudgetModel>> create({
    required String targetType,
    required double amount,
    String? categoryId,
    String? groupId,
    bool shared = false,
  }) =>
      _guard(() => _ds.create({
            'targetType': targetType,
            'amount': amount,
            'shared': shared,
            if (categoryId != null) 'categoryId': categoryId,
            if (groupId != null) 'groupId': groupId,
          }));

  Future<Result<void>> delete(String id) => _guard(() => _ds.delete(id));

  Future<Result<T>> _guard<T>(Future<T> Function() task) async {
    try {
      return Result.ok(await task());
    } catch (e) {
      return Result.err(mapDioError(e));
    }
  }
}
```
Run the test again → 2 pass.

- [ ] **Step 5: Providers** `lib/features/budgets/presentation/providers/budgets_providers.dart`:
```dart
import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/core/network/dio_client.dart';
import 'package:aifb/features/budgets/data/budgets_data_source.dart';
import 'package:aifb/features/budgets/data/budgets_repository.dart';
import 'package:aifb/features/budgets/data/models/budget_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final budgetsDataSourceProvider = Provider<BudgetsDataSource>((ref) {
  return BudgetsDataSource(ref.watch(dioProvider));
});

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return BudgetsRepository(ref.watch(budgetsDataSourceProvider));
});

final budgetsProvider =
    FutureProvider.autoDispose.family<List<BudgetModel>, Scope>((ref, scope) async {
  final result = await ref.watch(budgetsRepositoryProvider).list(scope: scope);
  return switch (result) {
    Ok<List<BudgetModel>>(value: final v) => v,
    Err<List<BudgetModel>>(failure: final f) => throw Exception(f.toString()),
  };
});
```

- [ ] **Step 6: Экран** `lib/features/budgets/presentation/pages/budgets_page.dart`:
```dart
import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/features/budgets/data/models/budget_model.dart';
import 'package:aifb/features/budgets/presentation/providers/budgets_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  Color _statusColor(String status) => switch (status) {
        'EXCEEDED' => Colors.red,
        'WARNING' => Colors.orange,
        _ => Colors.green,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(budgetsProvider(Scope.personal));
    final fmt = NumberFormat.decimalPattern();
    return Scaffold(
      appBar: AppBar(title: const Text('Бюджеты')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(budgetsProvider(Scope.personal).future),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [const SizedBox(height: 80), Center(child: Text('Ошибка: $e'))],
          ),
          data: (budgets) {
            if (budgets.isEmpty) {
              return ListView(
                children: const [SizedBox(height: 120), Center(child: Text('Лимитов пока нет'))],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: budgets.length,
              itemBuilder: (_, i) {
                final BudgetModel b = budgets[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(b.targetName,
                                style: const TextStyle(fontWeight: FontWeight.bold))),
                            Text('${fmt.format(b.spent)} / ${fmt.format(b.amount)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (b.percentage / 100).clamp(0, 1).toDouble(),
                          color: _statusColor(b.status),
                          backgroundColor: Colors.black12,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
```
(Создание/удаление лимита можно добавить кнопками позже; в рамках этой задачи экран показывает прогресс. Если хотите CRUD на экране — добавьте FAB по образцу `groups_page.dart`. Для прохождения задачи достаточно списка с прогресс-барами.)

ВАЖНО: чтобы не оставлять «мёртвый» репозиторий, добавьте простое удаление: на каждой карточке `trailing`-кнопку корзины, вызывающую `ref.read(budgetsRepositoryProvider).delete(b.id)` затем `ref.invalidate(budgetsProvider(Scope.personal))`. (Кнопку создания лимита оставляем на «развитие» — выбор цели требует списков категорий/групп; backend полностью готов.)

- [ ] **Step 7: Маршрут.** In `lib/app/router/routes.dart` App shell add `static const budgets = _Route('budgets', '/budgets');`. In `lib/app/router/app_router.dart` add import (relative) `import '../../features/budgets/presentation/pages/budgets_page.dart';` and GoRoute:
```dart
      GoRoute(
        path: AppRoutes.budgets.path,
        name: AppRoutes.budgets.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const BudgetsPage(),
        ),
      ),
```

- [ ] **Step 8: Предупреждение в форме операции.** In `lib/features/transactions/presentation/widgets/transaction_form_sheet.dart`: in `_submit`, after a successful create, the returned transaction (via repository) — currently `create` returns `Result<TransactionModel>`. On `Ok`, before popping, if `value.budgetWarnings.isNotEmpty`, show a SnackBar with the first warning. Concretely, in the `Ok` branch:
```dart
      case Ok<dynamic>(value: final tx):
        if (tx is TransactionModel && tx.budgetWarnings.isNotEmpty) {
          final w = tx.budgetWarnings.first;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Бюджет «${w.targetName}»: превышение (${w.status})')),
          );
        }
        Navigator.of(context).pop(true);
```
(Import `package:aifb/features/transactions/data/models/transaction_model.dart` if not already; the existing `Ok<dynamic>()` pattern must be changed to bind `value`. Verify `financeRepositoryProvider.create` returns `Result<TransactionModel>` — it does.)

- [ ] **Step 9: Анализ + тесты + commit**
```bash
cd frontend && flutter analyze lib && flutter test
git add frontend/lib/core/network/api_endpoints.dart frontend/lib/features/budgets frontend/lib/features/transactions/data/models/transaction_model.dart frontend/lib/features/transactions/presentation/widgets/transaction_form_sheet.dart frontend/lib/app/router/routes.dart frontend/lib/app/router/app_router.dart frontend/test/features/budgets
git commit -m "feat(frontend): фича budgets — прогресс лимитов + предупреждение в форме операции + маршрут"
```
Expected: analyze 0 errors/warnings (info ок); все тесты passed.

---

## Self-review (выполнено при написании плана)

- **Покрытие спеки:** `budget_limits` (V11, цель категория|группа, scope, уникальность на цель); расчёт «потрачено» за текущий месяц для категории и группы (EXPENSE, scope-aware, границы в Java); статусы OK/WARNING/EXCEEDED + percentage; CRUD с правами (личное/семейное, OWNER/ADULT, 409 на дубль, запрет INCOME-цели); мягкое предупреждение `budgetWarnings` в ответе create; фронт-фича `budgets` (экран с прогресс-барами + удаление) + предупреждение в форме. Все секции спеки покрыты.
- **Плейсхолдеры:** нет — полный код либо точечные правки с местом; единственная осознанная редукция UI (создание лимита из UI) явно отмечена как «развитие», backend полностью готов.
- **Согласованность типов:** `BudgetTargetType`/`BudgetStatus` объявлены в Task 1, используются в сервисе/DTO единообразно. `BudgetService.create/list/update/delete/warningsForExpense`, `BudgetResponse`, `BudgetWarning` согласованы между сервисом, контроллером, тестами и (для `BudgetWarning`) `TransactionResponse`. `Scope`, `HouseholdContext`, `CategoryRepository.findVisibleByIdPersonal/Family`, `CategoryGroupRepository.findByIdAndUserIdAndHouseholdIdIsNull/findByIdAndHouseholdId`, `Category.getGroupId()` — существующие, сигнатуры совпадают.
- **Заметка о spent в один запрос:** `sumExpenseForCategory`/`sumExpenseForGroup` принимают и `userId`, и `householdId`; ветка scope выбирается внутри JPQL через `(:householdId is null and ...) or (:householdId is not null and ...)`. Эквивалентно двум методам, но компактнее; проверяется тестами Task 2.
