# План 2 — Backend: Интеграция scope (личное/семейное)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Добавить семейный режим к категориям, транзакциям, целям и статистике: дискриминатор `household_id` (личное/семейное), параметр `scope=personal|family` в списках/статистике, флаг `shared` при создании, проверки прав по матрице, и `statistics/by-member`.

**Architecture:** В таблицы `categories`/`transactions`/`goals` добавляется `household_id UUID NULL` (FK→households, `ON DELETE CASCADE`). Видимость: `household_id IS NULL` → личное (по `user_id`), заданный → семейное. Финансовые сервисы получают контекст семьи через новый `HouseholdContextService` (грузит `household_id`+роль по `userId`), JWT/`AuthPrincipal` не меняются. Права: семейные категории/цели — OWNER/ADULT; семейные операции — любой участник, но править/удалять чужие может только OWNER/ADULT (CHILD — лишь свои).

**Tech Stack:** Spring Boot 3.3.5, Java 21, Spring Data JPA, PostgreSQL, Flyway; тесты — Testcontainers + MockMvc.

**Предусловие:** План 1 семейного бюджета реализован (`Household`, `HouseholdRole`, `User.householdId/householdRole`, `HouseholdService`). Финансовые модули из `feature/finance-core-and-goals` на месте.

---

## Структура файлов

**Создаваемые:**
- `backend/src/main/resources/db/migration/V9__finance_household_scope.sql`
- `.../household/service/HouseholdContextService.java` (+ запись `HouseholdContext`)
- `.../common/domain/Scope.java` — enum `PERSONAL`/`FAMILY`

**Изменяемые (entities + repos + services + controllers + dto):**
- `finance/category/**` (Category, CategoryRepository, CategoryService, CategoryController, dto)
- `finance/transaction/**`
- `finance/goal/**`
- `finance/statistics/**` (+ by-member)

**Изменяемые тесты:** существующие *ServiceIT/*ApiIT при необходимости (новые сценарии — отдельными тестами).

Команды `./gradlew` — из `backend/`, `JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home`, Docker запущен.

---

## Task 1: Миграция V9, поля household_id, контекст семьи, enum Scope

**Files:**
- Create: `backend/src/main/resources/db/migration/V9__finance_household_scope.sql`
- Create: `.../common/domain/Scope.java`
- Create: `.../household/service/HouseholdContextService.java`
- Modify: `finance/category/domain/Category.java`, `finance/transaction/domain/Transaction.java`, `finance/goal/domain/Goal.java`

- [ ] **Step 1: Миграция V9**

Create `backend/src/main/resources/db/migration/V9__finance_household_scope.sql`:
```sql
ALTER TABLE categories   ADD COLUMN household_id UUID REFERENCES households(id) ON DELETE CASCADE;
ALTER TABLE transactions ADD COLUMN household_id UUID REFERENCES households(id) ON DELETE CASCADE;
ALTER TABLE goals        ADD COLUMN household_id UUID REFERENCES households(id) ON DELETE CASCADE;

CREATE INDEX idx_categories_household   ON categories   (household_id) WHERE household_id IS NOT NULL;
CREATE INDEX idx_transactions_household ON transactions (household_id) WHERE household_id IS NOT NULL;
CREATE INDEX idx_goals_household        ON goals        (household_id) WHERE household_id IS NOT NULL;
```

- [ ] **Step 2: enum `Scope`**

Create `.../common/domain/Scope.java`:
```java
package com.aifb.platform.common.domain;

public enum Scope {
    PERSONAL,
    FAMILY
}
```

- [ ] **Step 3: `HouseholdContextService`**

Create `.../household/service/HouseholdContextService.java`:
```java
package com.aifb.platform.household.service;

import com.aifb.platform.auth.domain.User;
import com.aifb.platform.auth.repository.UserRepository;
import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.household.domain.HouseholdRole;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/** Доступ к членству пользователя в семье для финансовых модулей. */
@Service
public class HouseholdContextService {

    private final UserRepository userRepository;

    public HouseholdContextService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public record HouseholdContext(UUID householdId, HouseholdRole role) {
        public boolean canManageSharedContent() {
            return role == HouseholdRole.OWNER || role == HouseholdRole.ADULT;
        }
    }

    /** Семья пользователя или null, если он не состоит в семье. */
    @Transactional(readOnly = true)
    public HouseholdContext membershipOrNull(UUID userId) {
        User user = loadUser(userId);
        if (!user.isInHousehold()) {
            return null;
        }
        return new HouseholdContext(user.getHouseholdId(), user.getHouseholdRole());
    }

    /** Семья пользователя; 409 если он не в семье (для shared-создания). */
    @Transactional(readOnly = true)
    public HouseholdContext requireMembership(UUID userId) {
        HouseholdContext ctx = membershipOrNull(userId);
        if (ctx == null) {
            throw new ConflictException("Вы не состоите в семье");
        }
        return ctx;
    }

    /** Требует право управлять семейным контентом (категории/цели): OWNER/ADULT. */
    @Transactional(readOnly = true)
    public HouseholdContext requireManageSharedContent(UUID userId) {
        HouseholdContext ctx = requireMembership(userId);
        if (!ctx.canManageSharedContent()) {
            throw new ForbiddenException("Недостаточно прав для семейного контента");
        }
        return ctx;
    }

    private User loadUser(UUID userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Пользователь не найден"));
    }
}
```

- [ ] **Step 4: Добавить `householdId` в три сущности**

In `Category.java` add field (after `deletedAt`):
```java
    @Column(name = "household_id")
    private UUID householdId;
```
and getter + assignment helper (with the other getters):
```java
    public UUID getHouseholdId() { return householdId; }
    public boolean isShared() { return householdId != null; }
    public void assignHousehold(UUID householdId) { this.householdId = householdId; }
```

In `Transaction.java` add field + getter + `assignHousehold`:
```java
    @Column(name = "household_id")
    private UUID householdId;
```
```java
    public UUID getHouseholdId() { return householdId; }
    public boolean isShared() { return householdId != null; }
    public void assignHousehold(UUID householdId) { this.householdId = householdId; }
```

In `Goal.java` add field + getter + `assignHousehold`:
```java
    @Column(name = "household_id")
    private UUID householdId;
```
```java
    public UUID getHouseholdId() { return householdId; }
    public boolean isShared() { return householdId != null; }
    public void assignHousehold(UUID householdId) { this.householdId = householdId; }
```
(`UUID` already imported in all three.)

- [ ] **Step 5: Проверить схему**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.SmokeContextIT'
```
Expected: BUILD SUCCESSFUL (V9 применена, `validate` подтверждает новые колонки).

- [ ] **Step 6: Commit**
```bash
git add backend/src/main/resources/db/migration/V9__finance_household_scope.sql backend/src/main/java/com/aifb/platform/common/domain/Scope.java backend/src/main/java/com/aifb/platform/household/service/HouseholdContextService.java backend/src/main/java/com/aifb/platform/finance/category/domain/Category.java backend/src/main/java/com/aifb/platform/finance/transaction/domain/Transaction.java backend/src/main/java/com/aifb/platform/finance/goal/domain/Goal.java
git commit -m "feat(scope): миграция V9 household_id, Scope, HouseholdContextService"
```

---

## Task 2: Категории — scope в list/create/update/delete

**Files:**
- Modify: `finance/category/repository/CategoryRepository.java`
- Modify: `finance/category/service/CategoryService.java`
- Modify: `finance/category/api/dto/CategoryResponse.java`, `CreateCategoryRequest.java`
- Modify: `finance/category/api/CategoryController.java`
- Test: `backend/src/test/java/com/aifb/platform/finance/category/CategoryScopeIT.java`

- [ ] **Step 1: Репозиторий — scope-запросы**

In `CategoryRepository.java` add methods (keep existing ones):
```java
    @Query("""
            select c from Category c
            where c.deletedAt is null
              and (c.userId is null or (c.userId = :userId and c.householdId is null))
              and (:type is null or c.type = :type)
            order by c.system desc, c.name asc
            """)
    List<Category> findVisiblePersonal(@Param("userId") UUID userId,
                                       @Param("type") CategoryType type);

    @Query("""
            select c from Category c
            where c.deletedAt is null
              and (c.userId is null or c.householdId = :householdId)
              and (:type is null or c.type = :type)
            order by c.system desc, c.name asc
            """)
    List<Category> findVisibleFamily(@Param("householdId") UUID householdId,
                                     @Param("type") CategoryType type);

    @Query("""
            select c from Category c
            where c.id = :id and c.deletedAt is null
              and (c.userId is null or (c.userId = :userId and c.householdId is null))
            """)
    Optional<Category> findVisibleByIdPersonal(@Param("id") UUID id,
                                               @Param("userId") UUID userId);

    @Query("""
            select c from Category c
            where c.id = :id and c.deletedAt is null
              and (c.userId is null or c.householdId = :householdId)
            """)
    Optional<Category> findVisibleByIdFamily(@Param("id") UUID id,
                                             @Param("householdId") UUID householdId);

    boolean existsByHouseholdIdAndTypeAndNameIgnoreCaseAndDeletedAtIsNull(
            UUID householdId, CategoryType type, String name);
```

- [ ] **Step 2: DTO**

`CategoryResponse.java` — add `shared` field:
```java
package com.aifb.platform.finance.category.api.dto;

import com.aifb.platform.finance.category.domain.Category;

import java.util.UUID;

public record CategoryResponse(
        UUID id,
        String name,
        String type,
        String icon,
        String color,
        boolean system,
        boolean shared) {

    public static CategoryResponse from(Category c) {
        return new CategoryResponse(
                c.getId(), c.getName(), c.getType().name(),
                c.getIcon(), c.getColor(), c.isSystem(), c.isShared());
    }
}
```

`CreateCategoryRequest.java` — add `shared` (default false via nullable Boolean → treat null as false):
```java
package com.aifb.platform.finance.category.api.dto;

import com.aifb.platform.finance.category.domain.CategoryType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CreateCategoryRequest(
        @NotBlank @Size(max = 80) String name,
        @NotNull CategoryType type,
        @Size(max = 40) String icon,
        @Size(max = 9) String color,
        boolean shared) {
}
```
(Note: a missing `shared` in JSON deserializes to `false` for a primitive boolean record component — acceptable default.)

- [ ] **Step 3: Написать падающий тест**

Create `backend/src/test/java/com/aifb/platform/finance/category/CategoryScopeIT.java`:
```java
package com.aifb.platform.finance.category;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.finance.category.api.dto.CategoryResponse;
import com.aifb.platform.finance.category.api.dto.CreateCategoryRequest;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.domain.HouseholdRole;
import com.aifb.platform.household.service.HouseholdService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CategoryScopeIT extends AbstractIntegrationTest {

    @Autowired CategoryService service;
    @Autowired HouseholdService householdService;
    @Autowired TestAuth testAuth;

    @Test
    void sharedCategoryVisibleToFamilyNotPersonal() {
        UUID owner = testAuth.createUser().id();
        UUID member = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(member, new JoinHouseholdRequest(code));

        CategoryResponse shared = service.create(owner,
                new CreateCategoryRequest("Коммуналка", CategoryType.EXPENSE, null, null, true));
        assertThat(shared.shared()).isTrue();

        // видна обоим в family scope
        assertThat(service.list(owner, CategoryType.EXPENSE, Scope.FAMILY))
                .anyMatch(c -> c.id().equals(shared.id()));
        assertThat(service.list(member, CategoryType.EXPENSE, Scope.FAMILY))
                .anyMatch(c -> c.id().equals(shared.id()));
        // НЕ видна в personal scope
        assertThat(service.list(owner, CategoryType.EXPENSE, Scope.PERSONAL))
                .noneMatch(c -> c.id().equals(shared.id()));
    }

    @Test
    void childCannotCreateSharedCategory() {
        UUID owner = testAuth.createUser().id();
        UUID child = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(child, new JoinHouseholdRequest(code));
        householdService.changeRole(owner, child, HouseholdRole.CHILD);

        assertThatThrownBy(() -> service.create(child,
                new CreateCategoryRequest("X", CategoryType.EXPENSE, null, null, true)))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void sharedCreateWithoutHouseholdConflicts() {
        UUID solo = testAuth.createUser().id();
        assertThatThrownBy(() -> service.create(solo,
                new CreateCategoryRequest("X", CategoryType.EXPENSE, null, null, true)))
                .isInstanceOf(com.aifb.platform.common.exception.ConflictException.class);
    }

    @Test
    void adultCanDeleteSharedCategory() {
        UUID owner = testAuth.createUser().id();
        CategoryResponse shared = service.create(owner,
                new CreateCategoryRequest("Коммуналка", CategoryType.EXPENSE, null, null, true));
        service.delete(owner, shared.id());
        assertThat(service.list(owner, CategoryType.EXPENSE, Scope.FAMILY))
                .noneMatch(c -> c.id().equals(shared.id()));
    }
}
```

- [ ] **Step 2-run: Запустить — FAIL**
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.finance.category.CategoryScopeIT'
```
Expected: FAIL — сигнатура `service.list(userId, type, Scope)` и shared-логика ещё не реализованы.

- [ ] **Step 3: Обновить `CategoryService`**

Replace `CategoryService.java` with (вводит `Scope`, `shared`, права через `HouseholdContextService`):
```java
package com.aifb.platform.finance.category.service;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.category.api.dto.CategoryResponse;
import com.aifb.platform.finance.category.api.dto.CreateCategoryRequest;
import com.aifb.platform.finance.category.api.dto.UpdateCategoryRequest;
import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.repository.CategoryRepository;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class CategoryService {

    private final CategoryRepository repository;
    private final HouseholdContextService householdContext;

    public CategoryService(CategoryRepository repository,
                           HouseholdContextService householdContext) {
        this.repository = repository;
        this.householdContext = householdContext;
    }

    @Transactional(readOnly = true)
    public List<CategoryResponse> list(UUID userId, CategoryType type, Scope scope) {
        List<Category> categories;
        if (scope == Scope.FAMILY) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            categories = ctx == null ? List.of()
                    : repository.findVisibleFamily(ctx.householdId(), type);
        } else {
            categories = repository.findVisiblePersonal(userId, type);
        }
        return categories.stream().map(CategoryResponse::from).toList();
    }

    @Transactional
    public CategoryResponse create(UUID userId, CreateCategoryRequest req) {
        if (req.shared()) {
            HouseholdContext ctx = householdContext.requireManageSharedContent(userId);
            if (repository.existsByHouseholdIdAndTypeAndNameIgnoreCaseAndDeletedAtIsNull(
                    ctx.householdId(), req.type(), req.name())) {
                throw new ConflictException("Семейная категория с таким именем уже существует");
            }
            Category category = new Category(userId, req.name(), req.type(), req.icon(), req.color());
            category.assignHousehold(ctx.householdId());
            return CategoryResponse.from(repository.save(category));
        }
        if (repository.existsByUserIdAndTypeAndNameIgnoreCaseAndDeletedAtIsNull(
                userId, req.type(), req.name())) {
            throw new ConflictException("Категория с таким именем уже существует");
        }
        Category category = new Category(userId, req.name(), req.type(), req.icon(), req.color());
        return CategoryResponse.from(repository.save(category));
    }

    @Transactional
    public CategoryResponse update(UUID userId, UUID id, UpdateCategoryRequest req) {
        Category category = manageableCategory(userId, id);
        category.setName(req.name());
        category.setIcon(req.icon());
        category.setColor(req.color());
        return CategoryResponse.from(repository.save(category));
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        Category category = manageableCategory(userId, id);
        category.softDelete(Instant.now());
        repository.save(category);
    }

    /** Категория, которую пользователь вправе менять: своя личная, либо семейная при роли OWNER/ADULT. */
    private Category manageableCategory(UUID userId, UUID id) {
        Category category = repository.findById(id)
                .filter(c -> !c.isDeleted())
                .orElseThrow(() -> new NotFoundException("Категория не найдена"));
        if (category.isSystem()) {
            throw new ForbiddenException("Системные категории нельзя изменять");
        }
        if (category.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null || !ctx.householdId().equals(category.getHouseholdId())) {
                throw new NotFoundException("Категория не найдена");
            }
            if (!ctx.canManageSharedContent()) {
                throw new ForbiddenException("Недостаточно прав для семейной категории");
            }
            return category;
        }
        if (!userId.equals(category.getUserId())) {
            throw new NotFoundException("Категория не найдена");
        }
        return category;
    }
}
```

- [ ] **Step 4: Контроллер — `scope` в списке**

In `CategoryController.java`: add `import com.aifb.platform.common.domain.Scope;` and change `list(...)`:
```java
    @GetMapping
    public ApiResponse<List<CategoryResponse>> list(
            @CurrentUser AuthPrincipal principal,
            @RequestParam(required = false) CategoryType type,
            @RequestParam(defaultValue = "PERSONAL") Scope scope) {
        return ApiResponse.ok(service.list(principal.userId(), type, scope));
    }
```
(create/update/delete signatures unchanged — `shared` приходит в теле create.)

- [ ] **Step 5: Обновить существующий `CategoryServiceIT`**

The existing `CategoryServiceIT` calls `service.list(userId, type)` and `new CreateCategoryRequest(name,type,icon,color)`. Update every call:
- `service.list(uid, type)` → `service.list(uid, type, com.aifb.platform.common.domain.Scope.PERSONAL)`
- `new CreateCategoryRequest(a,b,c,d)` → `new CreateCategoryRequest(a,b,c,d,false)`
(add import `com.aifb.platform.common.domain.Scope;`). These keep the old behaviour (personal scope) green.

- [ ] **Step 6: Запустить категории целиком — PASS**
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.finance.category.*'
```
Expected: BUILD SUCCESSFUL (CategoryServiceIT 7 + CategoryApiIT 4 + CategoryScopeIT 4). Если `CategoryApiIT` шлёт JSON без `shared` — это ок (primitive boolean → false).

- [ ] **Step 7: Commit**
```bash
git add backend/src/main/java/com/aifb/platform/finance/category backend/src/test/java/com/aifb/platform/finance/category
git commit -m "feat(scope): семейные категории (scope в list, shared-создание, права OWNER/ADULT)"
```

---

## Task 3: Транзакции — scope + автор + права CHILD

**Files:**
- Modify: `finance/transaction/repository/TransactionRepository.java`
- Modify: `finance/transaction/service/TransactionService.java`
- Modify: `finance/transaction/api/dto/{TransactionResponse,CreateTransactionRequest,UpdateTransactionRequest}.java`
- Modify: `finance/transaction/api/TransactionController.java`
- Test: `backend/src/test/java/com/aifb/platform/finance/transaction/TransactionScopeIT.java`

- [ ] **Step 1: Репозиторий — scope-поиск**

In `TransactionRepository.java` add:
```java
    @Query("""
            select t from Transaction t
            where t.householdId = :householdId
              and (:from is null or t.occurredOn >= :from)
              and (:to is null or t.occurredOn <= :to)
              and (:type is null or t.type = :type)
              and (:categoryId is null or t.categoryId = :categoryId)
            """)
    Page<Transaction> searchFamily(@Param("householdId") UUID householdId,
                                   @Param("from") LocalDate from,
                                   @Param("to") LocalDate to,
                                   @Param("type") CategoryType type,
                                   @Param("categoryId") UUID categoryId,
                                   Pageable pageable);
```
Note: the existing `search(...)` already filters `t.userId = :userId`; ensure personal search excludes shared by adding `and t.householdId is null` — change the existing `search` query's where to include `and t.householdId is null`. Edit the existing `@Query` for `search` so its first line reads:
```java
            where t.userId = :userId and t.householdId is null
```

- [ ] **Step 2: DTO**

`TransactionResponse.java` — add `shared` and `authorId` (author = user_id):
```java
package com.aifb.platform.finance.transaction.api.dto;

import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.transaction.domain.Transaction;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

public record TransactionResponse(
        UUID id,
        UUID categoryId,
        String categoryName,
        String categoryColor,
        String categoryIcon,
        String type,
        BigDecimal amount,
        String note,
        LocalDate occurredOn,
        Instant createdAt,
        boolean shared,
        UUID authorId) {

    public static TransactionResponse from(Transaction t, Category category) {
        return new TransactionResponse(
                t.getId(), t.getCategoryId(),
                category == null ? null : category.getName(),
                category == null ? null : category.getColor(),
                category == null ? null : category.getIcon(),
                t.getType().name(), t.getAmount(), t.getNote(),
                t.getOccurredOn(), t.getCreatedAt(),
                t.isShared(), t.getUserId());
    }
}
```

`CreateTransactionRequest.java` — add `boolean shared` as last component (same validation block as existing, append `, boolean shared`). `UpdateTransactionRequest.java` — leave as-is (scope of an existing tx doesn't change on edit).

- [ ] **Step 3: Падающий тест**

Create `backend/src/test/java/com/aifb/platform/finance/transaction/TransactionScopeIT.java`:
```java
package com.aifb.platform.finance.transaction;

import com.aifb.platform.common.api.PageResponse;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
import com.aifb.platform.finance.transaction.api.dto.TransactionResponse;
import com.aifb.platform.finance.transaction.service.TransactionService;
import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.domain.HouseholdRole;
import com.aifb.platform.household.service.HouseholdService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class TransactionScopeIT extends AbstractIntegrationTest {

    @Autowired TransactionService service;
    @Autowired CategoryService categoryService;
    @Autowired HouseholdService householdService;
    @Autowired TestAuth testAuth;

    private UUID familyExpenseCat(UUID userId) {
        return categoryService.list(userId, CategoryType.EXPENSE, Scope.FAMILY).get(0).id();
    }

    @Test
    void sharedTransactionVisibleToFamilyWithAuthor() {
        UUID owner = testAuth.createUser().id();
        UUID member = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(member, new JoinHouseholdRequest(code));
        UUID cat = familyExpenseCat(owner); // системная категория видна в family

        TransactionResponse tx = service.create(member, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("100.00"), "общая", LocalDate.now(), true));
        assertThat(tx.shared()).isTrue();
        assertThat(tx.authorId()).isEqualTo(member);

        PageResponse<TransactionResponse> fam =
                service.list(owner, null, null, null, null, Scope.FAMILY, 0, 20);
        assertThat(fam.items()).anyMatch(t -> t.id().equals(tx.id()));
        // в личном scope автора её нет
        assertThat(service.list(member, null, null, null, null, Scope.PERSONAL, 0, 20).items())
                .noneMatch(t -> t.id().equals(tx.id()));
    }

    @Test
    void childCanCreateSharedTransaction() {
        UUID owner = testAuth.createUser().id();
        UUID child = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(child, new JoinHouseholdRequest(code));
        householdService.changeRole(owner, child, HouseholdRole.CHILD);
        UUID cat = familyExpenseCat(child);

        TransactionResponse tx = service.create(child, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("50.00"), null, LocalDate.now(), true));
        assertThat(tx.authorId()).isEqualTo(child);
    }

    @Test
    void childCannotEditOthersSharedTransaction() {
        UUID owner = testAuth.createUser().id();
        UUID child = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(child, new JoinHouseholdRequest(code));
        householdService.changeRole(owner, child, HouseholdRole.CHILD);
        UUID cat = familyExpenseCat(owner);

        TransactionResponse ownerTx = service.create(owner, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("100.00"), null, LocalDate.now(), true));
        assertThatThrownBy(() -> service.delete(child, ownerTx.id()))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void adultCanEditOthersSharedTransaction() {
        UUID owner = testAuth.createUser().id();
        UUID adult = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(adult, new JoinHouseholdRequest(code)); // ADULT по умолчанию
        UUID cat = familyExpenseCat(owner);

        TransactionResponse ownerTx = service.create(owner, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("100.00"), null, LocalDate.now(), true));
        service.delete(adult, ownerTx.id()); // не бросает
        assertThat(service.list(owner, null, null, null, null, Scope.FAMILY, 0, 20).items())
                .noneMatch(t -> t.id().equals(ownerTx.id()));
    }
}
```

- [ ] **Step 3-run: FAIL**
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.finance.transaction.TransactionScopeIT'
```
Expected: FAIL (нет `list(...Scope...)`, shared-логики, прав).

- [ ] **Step 4: Обновить `TransactionService`**

Rewrite `TransactionService.java`:
```java
package com.aifb.platform.finance.transaction.service;

import com.aifb.platform.common.api.PageResponse;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.common.exception.ErrorCode;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.repository.CategoryRepository;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
import com.aifb.platform.finance.transaction.api.dto.TransactionResponse;
import com.aifb.platform.finance.transaction.api.dto.UpdateTransactionRequest;
import com.aifb.platform.finance.transaction.domain.Transaction;
import com.aifb.platform.finance.transaction.repository.TransactionRepository;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class TransactionService {

    private final TransactionRepository repository;
    private final CategoryRepository categoryRepository;
    private final HouseholdContextService householdContext;

    public TransactionService(TransactionRepository repository,
                              CategoryRepository categoryRepository,
                              HouseholdContextService householdContext) {
        this.repository = repository;
        this.categoryRepository = categoryRepository;
        this.householdContext = householdContext;
    }

    @Transactional(readOnly = true)
    public PageResponse<TransactionResponse> list(UUID userId, LocalDate from, LocalDate to,
                                                  CategoryType type, UUID categoryId,
                                                  Scope scope, int page, int size) {
        Pageable pageable = PageRequest.of(page, size,
                Sort.by(Sort.Direction.DESC, "occurredOn")
                        .and(Sort.by(Sort.Direction.DESC, "createdAt")));
        Page<Transaction> result;
        if (scope == Scope.FAMILY) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            result = ctx == null ? Page.empty(pageable)
                    : repository.searchFamily(ctx.householdId(), from, to, type, categoryId, pageable);
        } else {
            result = repository.search(userId, from, to, type, categoryId, pageable);
        }
        Map<UUID, Category> categories = categoryRepository.findByIdIn(
                        result.getContent().stream().map(Transaction::getCategoryId).distinct().toList())
                .stream().collect(Collectors.toMap(Category::getId, Function.identity()));
        return PageResponse.from(result.map(
                t -> TransactionResponse.from(t, categories.get(t.getCategoryId()))));
    }

    @Transactional(readOnly = true)
    public TransactionResponse get(UUID userId, UUID id) {
        Transaction t = visibleTransaction(userId, id);
        return TransactionResponse.from(t, loadCategory(t.getCategoryId()));
    }

    @Transactional
    public TransactionResponse create(UUID userId, CreateTransactionRequest req) {
        if (req.shared()) {
            HouseholdContext ctx = householdContext.requireMembership(userId); // любой участник
            Category category = categoryRepository.findVisibleByIdFamily(req.categoryId(), ctx.householdId())
                    .orElseThrow(() -> new NotFoundException("Категория не найдена"));
            validateType(category, req.type());
            Transaction t = new Transaction(userId, category.getId(), req.type(),
                    req.amount(), req.note(), req.occurredOn());
            t.assignHousehold(ctx.householdId());
            return TransactionResponse.from(repository.save(t), category);
        }
        Category category = categoryRepository.findVisibleByIdPersonal(req.categoryId(), userId)
                .orElseThrow(() -> new NotFoundException("Категория не найдена"));
        validateType(category, req.type());
        Transaction t = new Transaction(userId, category.getId(), req.type(),
                req.amount(), req.note(), req.occurredOn());
        return TransactionResponse.from(repository.save(t), category);
    }

    @Transactional
    public TransactionResponse update(UUID userId, UUID id, UpdateTransactionRequest req) {
        Transaction t = editableTransaction(userId, id);
        Category category = resolveCategoryForExisting(userId, t, req.categoryId(), req.type());
        t.setCategoryId(category.getId());
        t.setType(req.type());
        t.setAmount(req.amount());
        t.setNote(req.note());
        t.setOccurredOn(req.occurredOn());
        return TransactionResponse.from(repository.save(t), category);
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        Transaction t = editableTransaction(userId, id);
        repository.delete(t);
    }

    // --- helpers ---

    private void validateType(Category category, CategoryType type) {
        if (category.getType() != type) {
            throw new DomainException(ErrorCode.VALIDATION_FAILED,
                    "Тип операции не совпадает с типом категории");
        }
    }

    /** Транзакция, видимая пользователю (своя личная или семейная его семьи). */
    private Transaction visibleTransaction(UUID userId, UUID id) {
        Transaction t = repository.findById(id)
                .orElseThrow(() -> new NotFoundException("Транзакция не найдена"));
        if (t.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null || !ctx.householdId().equals(t.getHouseholdId())) {
                throw new NotFoundException("Транзакция не найдена");
            }
            return t;
        }
        if (!userId.equals(t.getUserId())) {
            throw new NotFoundException("Транзакция не найдена");
        }
        return t;
    }

    /** Транзакция, которую пользователь вправе править/удалять. */
    private Transaction editableTransaction(UUID userId, UUID id) {
        Transaction t = visibleTransaction(userId, id);
        if (t.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            boolean own = userId.equals(t.getUserId());
            boolean canManage = ctx != null && ctx.canManageSharedContent();
            if (!own && !canManage) {
                throw new ForbiddenException("Нет прав на изменение чужой семейной операции");
            }
        }
        return t;
    }

    private Category resolveCategoryForExisting(UUID userId, Transaction t,
                                                UUID categoryId, CategoryType type) {
        Category category = t.isShared()
                ? categoryRepository.findVisibleByIdFamily(categoryId, t.getHouseholdId())
                    .orElseThrow(() -> new NotFoundException("Категория не найдена"))
                : categoryRepository.findVisibleByIdPersonal(categoryId, userId)
                    .orElseThrow(() -> new NotFoundException("Категория не найдена"));
        validateType(category, type);
        return category;
    }

    private Category loadCategory(UUID categoryId) {
        List<Category> found = categoryRepository.findByIdIn(List.of(categoryId));
        return found.isEmpty() ? null : found.get(0);
    }
}
```

- [ ] **Step 5: Контроллер — scope в list**

In `TransactionController.java`: add `import com.aifb.platform.common.domain.Scope;` and add to `list(...)` a param `@RequestParam(defaultValue = "PERSONAL") Scope scope` and pass it: `service.list(principal.userId(), from, to, type, categoryId, scope, page, size)`.

- [ ] **Step 6: Обновить существующий `TransactionServiceIT`**

Update calls: `service.list(uid, from, to, type, catId, page, size)` → add `Scope.PERSONAL` before `page` (import `com.aifb.platform.common.domain.Scope`); `new CreateTransactionRequest(cat,type,amount,note,date)` → append `, false`. `TransactionApiIT` JSON bodies without `shared` deserialize to false (ok).

- [ ] **Step 7: Запустить транзакции целиком — PASS**
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.finance.transaction.*'
```
Expected: BUILD SUCCESSFUL (ServiceIT 7 + ApiIT 3 + ScopeIT 4).

- [ ] **Step 8: Commit**
```bash
git add backend/src/main/java/com/aifb/platform/finance/transaction backend/src/test/java/com/aifb/platform/finance/transaction
git commit -m "feat(scope): семейные транзакции (scope, автор, права CHILD/ADULT)"
```

---

## Task 4: Цели — scope + права

**Files:**
- Modify: `finance/goal/repository/GoalRepository.java`
- Modify: `finance/goal/service/GoalService.java`
- Modify: `finance/goal/api/dto/{GoalResponse,CreateGoalRequest}.java`
- Modify: `finance/goal/api/GoalController.java`
- Test: `backend/src/test/java/com/aifb/platform/finance/goal/GoalScopeIT.java`

- [ ] **Step 1: Репозиторий**

In `GoalRepository.java` add:
```java
    List<Goal> findByHouseholdIdOrderByCreatedAtDesc(UUID householdId);
    Optional<Goal> findByIdAndHouseholdId(UUID id, UUID householdId);
```
And constrain the personal query: change `findByUserIdOrderByCreatedAtDesc` to `findByUserIdAndHouseholdIdIsNullOrderByCreatedAtDesc(UUID userId)`. Update the service call accordingly (Step 3).

- [ ] **Step 2: DTO**

`GoalResponse.java` — add `shared` (= householdId != null) as last component; in `from(Goal g, BigDecimal saved)` pass `g.isShared()`.
`CreateGoalRequest.java` — append `boolean shared` component.

- [ ] **Step 3: Падающий тест**

Create `backend/src/test/java/com/aifb/platform/finance/goal/GoalScopeIT.java`:
```java
package com.aifb.platform.finance.goal;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.finance.goal.api.dto.CreateContributionRequest;
import com.aifb.platform.finance.goal.api.dto.CreateGoalRequest;
import com.aifb.platform.finance.goal.api.dto.GoalResponse;
import com.aifb.platform.finance.goal.service.GoalService;
import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.domain.HouseholdRole;
import com.aifb.platform.household.service.HouseholdService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class GoalScopeIT extends AbstractIntegrationTest {

    @Autowired GoalService service;
    @Autowired HouseholdService householdService;
    @Autowired TestAuth testAuth;

    @Test
    void sharedGoalVisibleToFamilyAndContributable() {
        UUID owner = testAuth.createUser().id();
        UUID member = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(member, new JoinHouseholdRequest(code));

        GoalResponse goal = service.create(owner, new CreateGoalRequest(
                "Отпуск", new BigDecimal("1000.00"), LocalDate.now().plusMonths(3), null, null, true));
        assertThat(goal.shared()).isTrue();
        assertThat(service.list(member, Scope.FAMILY)).anyMatch(g -> g.id().equals(goal.id()));

        service.addContribution(member, goal.id(),
                new CreateContributionRequest(new BigDecimal("400.00"), null, LocalDate.now()));
        assertThat(service.get(owner, goal.id()).savedAmount()).isEqualByComparingTo("400.00");
    }

    @Test
    void childCannotCreateSharedGoal() {
        UUID owner = testAuth.createUser().id();
        UUID child = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(child, new JoinHouseholdRequest(code));
        householdService.changeRole(owner, child, HouseholdRole.CHILD);
        assertThatThrownBy(() -> service.create(child, new CreateGoalRequest(
                "X", new BigDecimal("100.00"), null, null, null, true)))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void personalGoalsExcludeShared() {
        UUID owner = testAuth.createUser().id();
        householdService.create(owner, new CreateHouseholdRequest("С"));
        GoalResponse shared = service.create(owner, new CreateGoalRequest(
                "Общая", new BigDecimal("500.00"), null, null, null, true));
        GoalResponse personal = service.create(owner, new CreateGoalRequest(
                "Личная", new BigDecimal("500.00"), null, null, null, false));
        assertThat(service.list(owner, Scope.PERSONAL)).anyMatch(g -> g.id().equals(personal.id()))
                .noneMatch(g -> g.id().equals(shared.id()));
    }
}
```

- [ ] **Step 3-run: FAIL**
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.finance.goal.GoalScopeIT'
```

- [ ] **Step 4: Обновить `GoalService`**

Inject `HouseholdContextService householdContext` (constructor). Changes:
- `list(UUID userId, Scope scope)`: FAMILY → `membershipOrNull`; if null → `List.of()`, else `findByHouseholdIdOrderByCreatedAtDesc(householdId)`; PERSONAL → `findByUserIdAndHouseholdIdIsNullOrderByCreatedAtDesc(userId)`. Прогресс — как раньше (sumByGoalIds).
- `create(userId, req)`: if `req.shared()` → `requireManageSharedContent(userId)` (OWNER/ADULT), create goal, `goal.assignHousehold(ctx.householdId())`. Else personal as before.
- `get/update/delete/listContributions/addContribution/deleteContribution`: replace `ownedGoal(userId, goalId)` with `accessibleGoal(userId, goalId)`:
  - load by id; if shared → require same household (404 otherwise); else require userId match (404).
  - For mutations on shared goal (update/delete/contributions add/delete): require `canManageSharedContent()` (OWNER/ADULT) → else `ForbiddenException`. (Взносы в семейную цель — OWNER/ADULT по матрице; CHILD не управляет целями.)
  - For personal goal: userId match suffices.

Full method bodies (replace `ownedGoal` usage):
```java
    private Goal accessibleGoal(UUID userId, UUID goalId) {
        Goal goal = goalRepository.findById(goalId)
                .orElseThrow(() -> new NotFoundException("Цель не найдена"));
        if (goal.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null || !ctx.householdId().equals(goal.getHouseholdId())) {
                throw new NotFoundException("Цель не найдена");
            }
            return goal;
        }
        if (!userId.equals(goal.getUserId())) {
            throw new NotFoundException("Цель не найдена");
        }
        return goal;
    }

    private Goal manageableGoal(UUID userId, UUID goalId) {
        Goal goal = accessibleGoal(userId, goalId);
        if (goal.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null || !ctx.canManageSharedContent()) {
                throw new ForbiddenException("Недостаточно прав для семейной цели");
            }
        }
        return goal;
    }
```
Use `accessibleGoal` in `get`/`listContributions`; use `manageableGoal` in `update`/`delete`/`addContribution`/`deleteContribution`. Add imports for `Scope`, `ForbiddenException`, `HouseholdContextService`/`HouseholdContext`.

- [ ] **Step 5: Контроллер**

In `GoalController.java`: add `import com.aifb.platform.common.domain.Scope;`; change `list` to accept `@RequestParam(defaultValue = "PERSONAL") Scope scope` and call `service.list(principal.userId(), scope)`.

- [ ] **Step 6: Обновить существующий `GoalServiceIT`**

`service.list(uid)` → `service.list(uid, Scope.PERSONAL)` (import Scope); `new CreateGoalRequest(name,target,deadline,icon,color)` → append `, false`. `GoalApiIT` JSON without `shared` → false (ok).

- [ ] **Step 7: Запустить цели целиком — PASS**
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.finance.goal.*'
```
Expected: BUILD SUCCESSFUL (GoalServiceIT 8 + GoalApiIT 3 + GoalScopeIT 3).

- [ ] **Step 8: Commit**
```bash
git add backend/src/main/java/com/aifb/platform/finance/goal backend/src/test/java/com/aifb/platform/finance/goal
git commit -m "feat(scope): семейные цели (scope, права OWNER/ADULT на управление)"
```

---

## Task 5: Статистика — scope + by-member

**Files:**
- Modify: `finance/transaction/repository/TransactionRepository.java` (family-aggregates + by-member)
- Modify: `finance/statistics/service/StatisticsService.java`
- Modify: `finance/statistics/api/StatisticsController.java`
- Create: `finance/statistics/api/dto/MemberBreakdownResponse.java`
- Test: `backend/src/test/java/com/aifb/platform/finance/statistics/StatisticsScopeIT.java`

- [ ] **Step 1: Репозиторий — семейные агрегаты и by-member**

In `TransactionRepository.java` add (mirrors existing personal aggregates but by household; и `by-member`):
```java
    @Query("""
            select t.type as type, coalesce(sum(t.amount), 0) as total
            from Transaction t
            where t.householdId = :householdId
              and (:from is null or t.occurredOn >= :from)
              and (:to is null or t.occurredOn <= :to)
            group by t.type
            """)
    List<TypeTotal> sumByTypeFamily(@Param("householdId") UUID householdId,
                                    @Param("from") LocalDate from, @Param("to") LocalDate to);

    @Query("""
            select t.categoryId as categoryId, coalesce(sum(t.amount), 0) as total
            from Transaction t
            where t.householdId = :householdId and t.type = :type
              and (:from is null or t.occurredOn >= :from)
              and (:to is null or t.occurredOn <= :to)
            group by t.categoryId order by total desc
            """)
    List<CategoryTotal> sumByCategoryFamily(@Param("householdId") UUID householdId,
                                            @Param("type") CategoryType type,
                                            @Param("from") LocalDate from, @Param("to") LocalDate to);

    @Query(value = """
            select to_char(occurred_on, 'YYYY-MM') as month,
                   coalesce(sum(amount) filter (where type = 'INCOME'), 0) as income,
                   coalesce(sum(amount) filter (where type = 'EXPENSE'), 0) as expense
            from transactions
            where household_id = :householdId
              and (cast(:from as date) is null or occurred_on >= :from)
              and (cast(:to as date) is null or occurred_on <= :to)
            group by 1 order by 1
            """, nativeQuery = true)
    List<TrendRow> trendFamily(@Param("householdId") UUID householdId,
                               @Param("from") LocalDate from, @Param("to") LocalDate to);

    interface MemberTotal {
        UUID getUserId();
        BigDecimal getIncome();
        BigDecimal getExpense();
    }

    @Query("""
            select t.userId as userId,
                   coalesce(sum(case when t.type = com.aifb.platform.finance.category.domain.CategoryType.INCOME then t.amount else 0 end), 0) as income,
                   coalesce(sum(case when t.type = com.aifb.platform.finance.category.domain.CategoryType.EXPENSE then t.amount else 0 end), 0) as expense
            from Transaction t
            where t.householdId = :householdId
            group by t.userId
            """)
    List<MemberTotal> sumByMember(@Param("householdId") UUID householdId);
```

- [ ] **Step 2: DTO by-member**

Create `finance/statistics/api/dto/MemberBreakdownResponse.java`:
```java
package com.aifb.platform.finance.statistics.api.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record MemberBreakdownResponse(
        UUID userId, String fullName, BigDecimal income, BigDecimal expense) {
}
```

- [ ] **Step 3: Падающий тест**

Create `backend/src/test/java/com/aifb/platform/finance/statistics/StatisticsScopeIT.java`:
```java
package com.aifb.platform.finance.statistics;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.finance.statistics.api.dto.MemberBreakdownResponse;
import com.aifb.platform.finance.statistics.api.dto.SummaryResponse;
import com.aifb.platform.finance.statistics.service.StatisticsService;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
import com.aifb.platform.finance.transaction.service.TransactionService;
import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.service.HouseholdService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class StatisticsScopeIT extends AbstractIntegrationTest {

    @Autowired StatisticsService service;
    @Autowired TransactionService txService;
    @Autowired CategoryService categoryService;
    @Autowired HouseholdService householdService;
    @Autowired TestAuth testAuth;

    @Test
    void familySummaryAndByMember() {
        TestAuth.AuthedUser ownerU = testAuth.createUser();
        TestAuth.AuthedUser memberU = testAuth.createUser();
        UUID owner = ownerU.id();
        UUID member = memberU.id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(member, new JoinHouseholdRequest(code));
        UUID cat = categoryService.list(owner, CategoryType.EXPENSE, Scope.FAMILY).get(0).id();

        txService.create(owner, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("300.00"), null, LocalDate.now(), true));
        txService.create(member, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("200.00"), null, LocalDate.now(), true));

        SummaryResponse fam = service.summary(owner, null, null, Scope.FAMILY);
        assertThat(fam.expense()).isEqualByComparingTo("500.00");

        List<MemberBreakdownResponse> byMember = service.byMember(owner);
        assertThat(byMember).hasSize(2);
        assertThat(byMember).allSatisfy(m -> assertThat(m.fullName()).isNotBlank());
        assertThat(byMember.stream().map(MemberBreakdownResponse::expense)
                .map(java.math.BigDecimal::stripTrailingZeros).toList())
                .contains(new BigDecimal("300.00").stripTrailingZeros(),
                          new BigDecimal("200.00").stripTrailingZeros());
    }

    @Test
    void personalSummaryExcludesFamily() {
        UUID owner = testAuth.createUser().id();
        householdService.create(owner, new CreateHouseholdRequest("С"));
        UUID famCat = categoryService.list(owner, CategoryType.EXPENSE, Scope.FAMILY).get(0).id();
        txService.create(owner, new CreateTransactionRequest(
                famCat, CategoryType.EXPENSE, new BigDecimal("300.00"), null, LocalDate.now(), true));
        SummaryResponse personal = service.summary(owner, null, null, Scope.PERSONAL);
        assertThat(personal.expense()).isEqualByComparingTo("0");
    }
}
```

- [ ] **Step 3-run: FAIL**
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.finance.statistics.StatisticsScopeIT'
```

- [ ] **Step 4: Обновить `StatisticsService`**

Inject `HouseholdContextService householdContext` and `UserRepository userRepository` (for member names). Changes:
- `summary(userId, from, to, Scope scope)`: FAMILY → `membershipOrNull`; null → zero summary; else `sumByTypeFamily(householdId,...)`. PERSONAL → existing `sumByType`. NOTE: personal `sumByType` currently aggregates ALL user transactions incl. shared — constrain it. Change the existing `sumByType`/`sumByCategory`/`trend` personal queries to add `and t.householdId is null` (personal excludes shared). Add `and household_id is null` to the native trend too.
- `byCategory(userId, type, from, to, scope)` and `trend(userId, from, to, scope)`: analogous family branch.
- New `byMember(userId)`: `requireMembership(userId)`; `sumByMember(householdId)`; map userIds → fullName via `userRepository.findByHouseholdId(householdId)` (build id→name map); return `MemberBreakdownResponse` list.

- [ ] **Step 5: Контроллер**

In `StatisticsController.java`: add `import com.aifb.platform.common.domain.Scope;`; add `@RequestParam(defaultValue = "PERSONAL") Scope scope` to `summary`/`by-category`/`trend` and pass through. Add endpoint:
```java
    @GetMapping("/by-member")
    public ApiResponse<List<MemberBreakdownResponse>> byMember(@CurrentUser AuthPrincipal principal) {
        return ApiResponse.ok(service.byMember(principal.userId()));
    }
```
(import `MemberBreakdownResponse`.)

- [ ] **Step 6: Обновить `StatisticsServiceIT`/`StatisticsApiIT`**

Existing service calls `service.summary(uid, from, to)` etc. → add `Scope.PERSONAL`. Api `/statistics/summary` без scope → default PERSONAL (ok, no change needed). Personal aggregates now exclude shared — existing tests use personal-only data, remain green.

- [ ] **Step 7: Запустить статистику целиком — PASS**
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.finance.statistics.*'
```

- [ ] **Step 8: Commit**
```bash
git add backend/src/main/java/com/aifb/platform/finance backend/src/test/java/com/aifb/platform/finance/statistics
git commit -m "feat(scope): семейная статистика + by-member; личные агрегаты исключают семейное"
```

---

## Task 6: Полный прогон и контроллерные scope-тесты

**Files:**
- Test: `backend/src/test/java/com/aifb/platform/finance/scope/ScopeApiIT.java`

- [ ] **Step 1: Написать web-тест scope (через HTTP)**

Create `backend/src/test/java/com/aifb/platform/finance/scope/ScopeApiIT.java`:
```java
package com.aifb.platform.finance.scope;

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

class ScopeApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired ObjectMapper objectMapper;

    @Test
    void sharedTransactionFlowViaHttp() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        // создать семью
        mockMvc.perform(post("/api/v1/households")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Семья\"}"))
                .andExpect(status().isOk());
        // взять семейную категорию EXPENSE
        MvcResult cats = mockMvc.perform(get("/api/v1/categories")
                        .param("type", "EXPENSE").param("scope", "FAMILY")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk()).andReturn();
        JsonNode arr = objectMapper.readTree(cats.getResponse().getContentAsString()).path("data");
        String catId = arr.get(0).path("id").asText();
        // создать семейную операцию
        mockMvc.perform(post("/api/v1/transactions")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"categoryId\":\"" + catId + "\",\"type\":\"EXPENSE\",\"amount\":100.00,\"occurredOn\":\"" + java.time.LocalDate.now() + "\",\"shared\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.shared").value(true));
        // видна в family scope, не видна в personal
        mockMvc.perform(get("/api/v1/transactions").param("scope", "FAMILY")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(jsonPath("$.data.total").value(1));
        mockMvc.perform(get("/api/v1/transactions").param("scope", "PERSONAL")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(jsonPath("$.data.total").value(0));
        // by-member
        mockMvc.perform(get("/api/v1/statistics/by-member")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1));
    }
}
```

- [ ] **Step 2: Запустить весь набор**
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test
```
Expected: BUILD SUCCESSFUL, все тесты (финансы + household + scope) passed. Сообщить итог.

- [ ] **Step 3: Commit**
```bash
git add backend/src/test/java/com/aifb/platform/finance/scope/ScopeApiIT.java
git commit -m "test(scope): сквозной web-тест семейного scope и by-member"
```

---

## Self-review (выполнено при написании плана)

- **Покрытие спеки:** `household_id` в трёх таблицах (V9, ON DELETE CASCADE — закрывает каскад при роспуске из Плана 1), `scope=personal|family` в списках категорий/транзакций/целей и статистике, `shared` при создании, права (категории/цели — OWNER/ADULT; операции — любой, правка чужих — OWNER/ADULT, CHILD только свои), `statistics/by-member`, автор операции в ответе. Личные агрегаты явно исключают семейное (`household_id is null`).
- **Плейсхолдеры:** нет — код приведён полностью либо как точечная правка с указанием места; обновление существующих тестов описано конкретными заменами сигнатур.
- **Согласованность типов:** `Scope` (PERSONAL/FAMILY) и `HouseholdContext{householdId, role, canManageSharedContent()}` объявлены в Task 1 и используются единообразно во всех сервисах/контроллерах. Новые сигнатуры `list(...Scope...)`, `summary(...Scope)`, `byMember(userId)`, проекции `MemberTotal` согласованы между репозиторием, сервисом, контроллером и тестами.
- **Совместимость:** добавление `shared`/`scope` с дефолтом `false`/`PERSONAL` сохраняет старое (личное) поведение; существующие тесты обновляются механически (добавить `Scope.PERSONAL` / `, false`).
