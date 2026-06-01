# План — Авто-категоризация

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Правила «ключевое слово → категория» (личные): CRUD, подбор категории по тексту заметки (самое длинное совпадение, фильтр по типу), авто-присвоение при создании личной операции без категории и эндпоинт-подсказка.

**Architecture:** Новый модуль `finance/categorization`. Сущность `CategorizationRule` (личная: `user_id`, `keyword`, `category_id`). Подбор — в сервисе: правила пользователя, чья категория совпадает по типу, фильтр по подстроке в `note` (без регистра), сортировка по длине keyword. `TransactionService.create` при отсутствии `categoryId` (только для личных операций) подбирает категорию через `CategorizationService`. Зависимость transaction→categorization (однонаправленная).

**Tech Stack:** Spring Boot 3.3.5, Java 21, Spring Data JPA, PostgreSQL, Flyway; Flutter 3.44 (Riverpod/Dio); тесты — Testcontainers + MockMvc + mocktail.

**Предусловие:** ветка `feature/auto-categorization` (от `feature/budget-limits`). Категории (`CategoryRepository.findVisibleByIdPersonal`, `Category.getType()/getName()`), транзакции (`TransactionService.create` с ветками shared/personal), `CategoryType` реализованы.

---

## Структура файлов

**Backend создаваемые:**
- `backend/src/main/resources/db/migration/V12__categorization_rules.sql`
- `finance/categorization/domain/CategorizationRule.java`
- `finance/categorization/repository/CategorizationRuleRepository.java`
- `finance/categorization/service/CategorizationService.java`
- `finance/categorization/api/CategorizationController.java`
- `finance/categorization/api/dto/{RuleResponse,CreateRuleRequest,UpdateRuleRequest,SuggestRequest,SuggestResponse}.java`

**Backend изменяемые:**
- `finance/transaction/api/dto/CreateTransactionRequest.java` (`categoryId` → необязательный)
- `finance/transaction/service/TransactionService.java` (авто-подбор при создании)

**Frontend создаваемые:** `features/categorization/data/models/rule_model.dart`, `.../data/categorization_data_source.dart`, `.../data/categorization_repository.dart`, `.../presentation/providers/categorization_providers.dart`, `.../presentation/pages/rules_page.dart`, `test/features/categorization/categorization_repository_test.dart`; route.

**Тесты backend:** `finance/categorization/CategorizationServiceIT.java`, `CategorizationApiIT.java`, `finance/transaction/AutoCategorizeIT.java`.

Команды backend — из `backend/`, `JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home`; Docker запущен. Frontend — из `frontend/`.

---

## Task 1: Миграция V12, сущность, репозиторий

**Files:** V12 sql; `CategorizationRule.java`; `CategorizationRuleRepository.java`.

- [ ] **Step 1: Миграция** `backend/src/main/resources/db/migration/V12__categorization_rules.sql`:
```sql
CREATE TABLE categorization_rules (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    keyword VARCHAR(80) NOT NULL,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX uk_categorization_rules_user_keyword
    ON categorization_rules (user_id, lower(keyword));
```

- [ ] **Step 2: Сущность** `finance/categorization/domain/CategorizationRule.java`:
```java
package com.aifb.platform.finance.categorization.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "categorization_rules")
public class CategorizationRule extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(nullable = false, length = 80)
    private String keyword;

    @Column(name = "category_id", nullable = false)
    private UUID categoryId;

    protected CategorizationRule() {
    }

    public CategorizationRule(UUID userId, String keyword, UUID categoryId) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.keyword = keyword;
        this.categoryId = categoryId;
    }

    public UUID getUserId() { return userId; }
    public String getKeyword() { return keyword; }
    public UUID getCategoryId() { return categoryId; }

    public void setKeyword(String keyword) { this.keyword = keyword; }
    public void setCategoryId(UUID categoryId) { this.categoryId = categoryId; }
}
```

- [ ] **Step 3: Репозиторий** `finance/categorization/repository/CategorizationRuleRepository.java`:
```java
package com.aifb.platform.finance.categorization.repository;

import com.aifb.platform.finance.categorization.domain.CategorizationRule;
import com.aifb.platform.finance.category.domain.CategoryType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CategorizationRuleRepository extends JpaRepository<CategorizationRule, UUID> {

    List<CategorizationRule> findByUserIdOrderByCreatedAtDesc(UUID userId);

    Optional<CategorizationRule> findByIdAndUserId(UUID id, UUID userId);

    boolean existsByUserIdAndKeywordIgnoreCase(UUID userId, String keyword);

    /** Правила пользователя, чья категория имеет данный тип; самые специфичные (длинный keyword) первыми. */
    @Query("""
            select r from CategorizationRule r, com.aifb.platform.finance.category.domain.Category c
            where r.categoryId = c.id and r.userId = :userId and c.type = :type
            order by length(r.keyword) desc, r.createdAt desc
            """)
    List<CategorizationRule> findForMatching(@Param("userId") UUID userId,
                                             @Param("type") CategoryType type);
}
```

- [ ] **Step 4: Проверить схему**
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.SmokeContextIT'
```
Expected: BUILD SUCCESSFUL (V12 применена; JPQL `findForMatching` валидируется при старте).

- [ ] **Step 5: Commit**
```bash
git add backend/src/main/resources/db/migration/V12__categorization_rules.sql backend/src/main/java/com/aifb/platform/finance/categorization/domain backend/src/main/java/com/aifb/platform/finance/categorization/repository
git commit -m "feat(categorization): миграция V12, сущность CategorizationRule, репозиторий"
```

---

## Task 2: DTO, CategorizationService (CRUD + resolve), тесты

**Files:** dto x5; `CategorizationService.java`; test `CategorizationServiceIT.java`.

- [ ] **Step 1: DTO (create all 5).**
`finance/categorization/api/dto/RuleResponse.java`:
```java
package com.aifb.platform.finance.categorization.api.dto;

import java.util.UUID;

public record RuleResponse(UUID id, String keyword, UUID categoryId, String categoryName) {
}
```
`finance/categorization/api/dto/CreateRuleRequest.java`:
```java
package com.aifb.platform.finance.categorization.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record CreateRuleRequest(
        @NotBlank @Size(max = 80) String keyword,
        @NotNull UUID categoryId) {
}
```
`finance/categorization/api/dto/UpdateRuleRequest.java`:
```java
package com.aifb.platform.finance.categorization.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record UpdateRuleRequest(
        @NotBlank @Size(max = 80) String keyword,
        @NotNull UUID categoryId) {
}
```
`finance/categorization/api/dto/SuggestRequest.java`:
```java
package com.aifb.platform.finance.categorization.api.dto;

import com.aifb.platform.finance.category.domain.CategoryType;
import jakarta.validation.constraints.NotNull;

public record SuggestRequest(String note, @NotNull CategoryType type) {
}
```
`finance/categorization/api/dto/SuggestResponse.java`:
```java
package com.aifb.platform.finance.categorization.api.dto;

import java.util.UUID;

public record SuggestResponse(UUID categoryId, String categoryName) {
}
```

- [ ] **Step 2: Падающий тест** `backend/src/test/java/com/aifb/platform/finance/categorization/CategorizationServiceIT.java`:
```java
package com.aifb.platform.finance.categorization;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.categorization.api.dto.CreateRuleRequest;
import com.aifb.platform.finance.categorization.api.dto.RuleResponse;
import com.aifb.platform.finance.categorization.service.CategorizationService;
import com.aifb.platform.finance.category.api.dto.CategoryResponse;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CategorizationServiceIT extends AbstractIntegrationTest {

    @Autowired CategorizationService service;
    @Autowired CategoryService categoryService;
    @Autowired TestAuth testAuth;

    private List<CategoryResponse> expenseCats(UUID userId) {
        return categoryService.list(userId, CategoryType.EXPENSE, Scope.PERSONAL);
    }

    @Test
    void createRuleAndList() {
        UUID userId = testAuth.createUser().id();
        UUID cat = expenseCats(userId).get(0).id();
        RuleResponse r = service.create(userId, new CreateRuleRequest("magnum", cat));
        assertThat(r.keyword()).isEqualTo("magnum");
        assertThat(r.categoryName()).isNotBlank();
        assertThat(service.list(userId)).anyMatch(x -> x.id().equals(r.id()));
    }

    @Test
    void duplicateKeywordConflicts() {
        UUID userId = testAuth.createUser().id();
        UUID cat = expenseCats(userId).get(0).id();
        service.create(userId, new CreateRuleRequest("Magnum", cat));
        assertThatThrownBy(() -> service.create(userId, new CreateRuleRequest("magnum", cat)))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void ruleWithForeignCategoryRejected() {
        UUID owner = testAuth.createUser().id();
        UUID other = testAuth.createUser().id();
        CategoryResponse ownCat = categoryService.create(owner,
                new com.aifb.platform.finance.category.api.dto.CreateCategoryRequest(
                        "Личная", CategoryType.EXPENSE, null, null, false, null));
        assertThatThrownBy(() -> service.create(other, new CreateRuleRequest("x", ownCat.id())))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void resolveMatchesSubstringCaseInsensitive() {
        UUID userId = testAuth.createUser().id();
        UUID cat = expenseCats(userId).get(0).id();
        service.create(userId, new CreateRuleRequest("magnum", cat));
        assertThat(service.resolve(userId, "Покупка в MAGNUM на Абая", CategoryType.EXPENSE))
                .contains(cat);
        assertThat(service.resolve(userId, "Такси", CategoryType.EXPENSE)).isEmpty();
    }

    @Test
    void resolveLongestKeywordWins() {
        UUID userId = testAuth.createUser().id();
        List<CategoryResponse> cats = expenseCats(userId);
        UUID food = cats.get(0).id();
        UUID transport = cats.get(1).id();
        service.create(userId, new CreateRuleRequest("market", food));
        service.create(userId, new CreateRuleRequest("super market", transport));
        // более длинное правило выигрывает
        assertThat(service.resolve(userId, "оплата super market", CategoryType.EXPENSE))
                .contains(transport);
    }

    @Test
    void resolveFiltersByType() {
        UUID userId = testAuth.createUser().id();
        UUID expenseCat = expenseCats(userId).get(0).id();
        service.create(userId, new CreateRuleRequest("salary", expenseCat));
        // правило ведёт на EXPENSE-категорию, а запрос INCOME → нет совпадения
        assertThat(service.resolve(userId, "salary", CategoryType.INCOME)).isEmpty();
    }
}
```
Run `cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.finance.categorization.CategorizationServiceIT'` → FAIL.

- [ ] **Step 3: Сервис** `finance/categorization/service/CategorizationService.java`:
```java
package com.aifb.platform.finance.categorization.service;

import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.categorization.api.dto.CreateRuleRequest;
import com.aifb.platform.finance.categorization.api.dto.RuleResponse;
import com.aifb.platform.finance.categorization.api.dto.UpdateRuleRequest;
import com.aifb.platform.finance.categorization.domain.CategorizationRule;
import com.aifb.platform.finance.categorization.repository.CategorizationRuleRepository;
import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.repository.CategoryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class CategorizationService {

    private final CategorizationRuleRepository repository;
    private final CategoryRepository categoryRepository;

    public CategorizationService(CategorizationRuleRepository repository,
                                 CategoryRepository categoryRepository) {
        this.repository = repository;
        this.categoryRepository = categoryRepository;
    }

    @Transactional(readOnly = true)
    public List<RuleResponse> list(UUID userId) {
        return repository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(this::toResponse).toList();
    }

    @Transactional
    public RuleResponse create(UUID userId, CreateRuleRequest req) {
        requireOwnVisibleCategory(userId, req.categoryId());
        if (repository.existsByUserIdAndKeywordIgnoreCase(userId, req.keyword())) {
            throw new ConflictException("Правило с таким ключевым словом уже есть");
        }
        CategorizationRule rule = new CategorizationRule(userId, req.keyword(), req.categoryId());
        return toResponse(repository.save(rule));
    }

    @Transactional
    public RuleResponse update(UUID userId, UUID id, UpdateRuleRequest req) {
        CategorizationRule rule = repository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new NotFoundException("Правило не найдено"));
        requireOwnVisibleCategory(userId, req.categoryId());
        if (!rule.getKeyword().equalsIgnoreCase(req.keyword())
                && repository.existsByUserIdAndKeywordIgnoreCase(userId, req.keyword())) {
            throw new ConflictException("Правило с таким ключевым словом уже есть");
        }
        rule.setKeyword(req.keyword());
        rule.setCategoryId(req.categoryId());
        return toResponse(repository.save(rule));
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        CategorizationRule rule = repository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new NotFoundException("Правило не найдено"));
        repository.delete(rule);
    }

    /** Подбор категории по тексту заметки (личные правила, фильтр по типу, самое длинное слово). */
    @Transactional(readOnly = true)
    public Optional<UUID> resolve(UUID userId, String note, CategoryType type) {
        if (note == null || note.isBlank()) {
            return Optional.empty();
        }
        String lower = note.toLowerCase();
        return repository.findForMatching(userId, type).stream()
                .filter(r -> lower.contains(r.getKeyword().toLowerCase()))
                .map(CategorizationRule::getCategoryId)
                .findFirst();
    }

    private void requireOwnVisibleCategory(UUID userId, UUID categoryId) {
        categoryRepository.findVisibleByIdPersonal(categoryId, userId)
                .orElseThrow(() -> new NotFoundException("Категория не найдена"));
    }

    private RuleResponse toResponse(CategorizationRule rule) {
        String name = categoryRepository.findById(rule.getCategoryId())
                .map(Category::getName).orElse("—");
        return new RuleResponse(rule.getId(), rule.getKeyword(), rule.getCategoryId(), name);
    }
}
```

- [ ] **Step 4: Run** `... --tests 'com.aifb.platform.finance.categorization.CategorizationServiceIT'` → BUILD SUCCESSFUL, 6 tests.

- [ ] **Step 5: Commit**
```bash
git add backend/src/main/java/com/aifb/platform/finance/categorization/api/dto backend/src/main/java/com/aifb/platform/finance/categorization/service backend/src/test/java/com/aifb/platform/finance/categorization/CategorizationServiceIT.java
git commit -m "feat(categorization): сервис правил (CRUD + resolve по тексту) с тестами"
```

---

## Task 3: Контроллер (правила + suggest) и web-тесты

**Files:** `CategorizationController.java`; test `CategorizationApiIT.java`.

- [ ] **Step 1: Падающий web-тест** `backend/src/test/java/com/aifb/platform/finance/categorization/CategorizationApiIT.java`:
```java
package com.aifb.platform.finance.categorization;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
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

class CategorizationApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired CategoryService categoryService;

    @Test
    void rulesRequireAuth() throws Exception {
        mockMvc.perform(get("/api/v1/categorization/rules"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void createRuleAndSuggest() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        UUID cat = categoryService.list(user.id(), CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
        mockMvc.perform(post("/api/v1/categorization/rules")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"keyword\":\"magnum\",\"categoryId\":\"" + cat + "\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.keyword").value("magnum"));

        mockMvc.perform(post("/api/v1/categorization/suggest")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"note\":\"покупка в MAGNUM\",\"type\":\"EXPENSE\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.categoryId").value(cat.toString()));
    }

    @Test
    void suggestNoMatchReturnsNullData() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        mockMvc.perform(post("/api/v1/categorization/suggest")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"note\":\"ничего\",\"type\":\"EXPENSE\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").doesNotExist());
    }
}
```
(`$.data` отсутствует при null — `default-property-inclusion: non_null`.)
Run → FAIL.

- [ ] **Step 2: Контроллер** `finance/categorization/api/CategorizationController.java`:
```java
package com.aifb.platform.finance.categorization.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.finance.categorization.api.dto.CreateRuleRequest;
import com.aifb.platform.finance.categorization.api.dto.RuleResponse;
import com.aifb.platform.finance.categorization.api.dto.SuggestRequest;
import com.aifb.platform.finance.categorization.api.dto.SuggestResponse;
import com.aifb.platform.finance.categorization.api.dto.UpdateRuleRequest;
import com.aifb.platform.finance.categorization.service.CategorizationService;
import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.repository.CategoryRepository;
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
@RequestMapping("/api/v1/categorization")
public class CategorizationController {

    private final CategorizationService service;
    private final CategoryRepository categoryRepository;

    public CategorizationController(CategorizationService service,
                                    CategoryRepository categoryRepository) {
        this.service = service;
        this.categoryRepository = categoryRepository;
    }

    @GetMapping("/rules")
    public ApiResponse<List<RuleResponse>> list(@CurrentUser AuthPrincipal principal) {
        return ApiResponse.ok(service.list(principal.userId()));
    }

    @PostMapping("/rules")
    public ApiResponse<RuleResponse> create(
            @CurrentUser AuthPrincipal principal,
            @Valid @RequestBody CreateRuleRequest request) {
        return ApiResponse.ok(service.create(principal.userId(), request));
    }

    @PutMapping("/rules/{id}")
    public ApiResponse<RuleResponse> update(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id,
            @Valid @RequestBody UpdateRuleRequest request) {
        return ApiResponse.ok(service.update(principal.userId(), id, request));
    }

    @DeleteMapping("/rules/{id}")
    public ApiResponse<Void> delete(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id) {
        service.delete(principal.userId(), id);
        return ApiResponse.ok(null);
    }

    @PostMapping("/suggest")
    public ApiResponse<SuggestResponse> suggest(
            @CurrentUser AuthPrincipal principal,
            @Valid @RequestBody SuggestRequest request) {
        return ApiResponse.ok(service.resolve(principal.userId(), request.note(), request.type())
                .map(categoryId -> new SuggestResponse(
                        categoryId,
                        categoryRepository.findById(categoryId).map(Category::getName).orElse("—")))
                .orElse(null));
    }
}
```

- [ ] **Step 3: Run** `... --tests 'com.aifb.platform.finance.categorization.CategorizationApiIT'` → BUILD SUCCESSFUL, 3 tests.

- [ ] **Step 4: Commit**
```bash
git add backend/src/main/java/com/aifb/platform/finance/categorization/api/CategorizationController.java backend/src/test/java/com/aifb/platform/finance/categorization/CategorizationApiIT.java
git commit -m "feat(categorization): REST-контроллер правил и подсказки с web-тестами"
```

---

## Task 4: Авто-присвоение при создании операции

**Files:** modify `CreateTransactionRequest.java`, `TransactionService.java`; test `finance/transaction/AutoCategorizeIT.java`.

- [ ] **Step 1: `CreateTransactionRequest` — `categoryId` необязателен.** Remove `@NotNull` from `categoryId` (keep the field):
```java
package com.aifb.platform.finance.transaction.api.dto;

import com.aifb.platform.finance.category.domain.CategoryType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public record CreateTransactionRequest(
        UUID categoryId,
        @NotNull CategoryType type,
        @NotNull @DecimalMin(value = "0.01") @Digits(integer = 13, fraction = 2) BigDecimal amount,
        @Size(max = 255) String note,
        @NotNull @PastOrPresent LocalDate occurredOn,
        boolean shared) {
}
```

- [ ] **Step 2: Падающий тест** `backend/src/test/java/com/aifb/platform/finance/transaction/AutoCategorizeIT.java`:
```java
package com.aifb.platform.finance.transaction;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.finance.categorization.api.dto.CreateRuleRequest;
import com.aifb.platform.finance.categorization.service.CategorizationService;
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
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class AutoCategorizeIT extends AbstractIntegrationTest {

    @Autowired TransactionService transactionService;
    @Autowired CategorizationService categorizationService;
    @Autowired CategoryService categoryService;
    @Autowired TestAuth testAuth;

    @Test
    void personalTransactionWithoutCategoryResolvedByRule() {
        UUID userId = testAuth.createUser().id();
        UUID cat = categoryService.list(userId, CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
        categorizationService.create(userId, new CreateRuleRequest("magnum", cat));

        TransactionResponse tx = transactionService.create(userId, new CreateTransactionRequest(
                null, CategoryType.EXPENSE, new BigDecimal("100.00"), "Покупка MAGNUM", LocalDate.now(), false));
        assertThat(tx.categoryId()).isEqualTo(cat);
    }

    @Test
    void noRuleMatchWithoutCategoryRejected() {
        UUID userId = testAuth.createUser().id();
        assertThatThrownBy(() -> transactionService.create(userId, new CreateTransactionRequest(
                null, CategoryType.EXPENSE, new BigDecimal("100.00"), "Что-то", LocalDate.now(), false)))
                .isInstanceOf(DomainException.class);
    }

    @Test
    void sharedTransactionWithoutCategoryRejected() {
        UUID userId = testAuth.createUser().id();
        assertThatThrownBy(() -> transactionService.create(userId, new CreateTransactionRequest(
                null, CategoryType.EXPENSE, new BigDecimal("100.00"), "MAGNUM", LocalDate.now(), true)))
                .isInstanceOf(DomainException.class);
    }

    @Test
    void explicitCategoryNotOverriddenByRule() {
        UUID userId = testAuth.createUser().id();
        var cats = categoryService.list(userId, CategoryType.EXPENSE, Scope.PERSONAL);
        UUID ruleCat = cats.get(0).id();
        UUID chosenCat = cats.get(1).id();
        categorizationService.create(userId, new CreateRuleRequest("magnum", ruleCat));
        TransactionResponse tx = transactionService.create(userId, new CreateTransactionRequest(
                chosenCat, CategoryType.EXPENSE, new BigDecimal("100.00"), "MAGNUM", LocalDate.now(), false));
        assertThat(tx.categoryId()).isEqualTo(chosenCat);
    }
}
```
Run → FAIL.

- [ ] **Step 3: Обновить `TransactionService`.** Inject `CategorizationService categorizationService` (constructor param + field; add import `com.aifb.platform.finance.categorization.service.CategorizationService`). Replace the `create(...)` method body's branches so the personal branch auto-resolves and the shared branch requires a category. Use this exact `create`:
```java
    @Transactional
    public TransactionResponse create(UUID userId, CreateTransactionRequest req) {
        Category category;
        Transaction t;
        if (req.shared()) {
            if (req.categoryId() == null) {
                throw new DomainException(ErrorCode.VALIDATION_FAILED,
                        "Категория обязательна для семейной операции");
            }
            HouseholdContext ctx = householdContext.requireMembership(userId);
            category = categoryRepository.findVisibleByIdFamily(req.categoryId(), ctx.householdId())
                    .orElseThrow(() -> new NotFoundException("Категория не найдена"));
            validateType(category, req.type());
            t = new Transaction(userId, category.getId(), req.type(),
                    req.amount(), req.note(), req.occurredOn());
            t.assignHousehold(ctx.householdId());
        } else {
            UUID categoryId = req.categoryId();
            if (categoryId == null) {
                categoryId = categorizationService.resolve(userId, req.note(), req.type())
                        .orElseThrow(() -> new DomainException(ErrorCode.VALIDATION_FAILED,
                                "Категория не определена"));
            }
            category = categoryRepository.findVisibleByIdPersonal(categoryId, userId)
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
(Keep all other methods unchanged. `DomainException`, `ErrorCode`, `BudgetWarning`, `HouseholdContext`, `List`, `CategoryType` already imported from prior tasks.)

- [ ] **Step 4: Run** `... --tests 'com.aifb.platform.finance.transaction.AutoCategorizeIT'` → BUILD SUCCESSFUL, 4 tests.

- [ ] **Step 5: Full suite + commit.** Existing transaction tests pass categoryId, so removing `@NotNull` doesn't break them (provided category → used directly).
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test
git add backend/src/main/java/com/aifb/platform/finance/transaction backend/src/test/java/com/aifb/platform/finance/transaction/AutoCategorizeIT.java
git commit -m "feat(categorization): авто-присвоение категории при создании личной операции"
```
Report total backend test count.

---

## Task 5: Frontend — фича categorization (правила + подсказка в форме)

**Files:** rule model/data source/repo/providers/page; route; transaction form suggest.

- [ ] **Step 1: Endpoint + model.**
In `lib/core/network/api_endpoints.dart` add: `static const String categorizationRules = '/categorization/rules';` and `static const String categorizationSuggest = '/categorization/suggest';`
Create `lib/features/categorization/data/models/rule_model.dart`:
```dart
class RuleModel {
  const RuleModel({
    required this.id,
    required this.keyword,
    required this.categoryId,
    required this.categoryName,
  });

  factory RuleModel.fromJson(Map<String, dynamic> json) => RuleModel(
        id: json['id'] as String,
        keyword: json['keyword'] as String,
        categoryId: json['categoryId'] as String,
        categoryName: json['categoryName'] as String,
      );

  final String id;
  final String keyword;
  final String categoryId;
  final String categoryName;
}
```

- [ ] **Step 2: Data source** `lib/features/categorization/data/categorization_data_source.dart`:
```dart
import 'package:aifb/core/network/api_endpoints.dart';
import 'package:aifb/core/network/envelope.dart';
import 'package:aifb/features/categorization/data/models/rule_model.dart';
import 'package:dio/dio.dart';

class CategorizationDataSource {
  CategorizationDataSource(this._dio);
  final Dio _dio;

  Future<List<RuleModel>> list() async {
    final res =
        await _dio.get<Map<String, dynamic>>(ApiEndpoints.categorizationRules);
    return unwrapList(res.data)
        .map((e) => RuleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RuleModel> create(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.categorizationRules, data: body);
    return RuleModel.fromJson(unwrapObject(res.data));
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('${ApiEndpoints.categorizationRules}/$id');
  }

  /// Подсказка категории по тексту; null если совпадений нет.
  Future<String?> suggest(String note, String type) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.categorizationSuggest,
      data: {'note': note, 'type': type},
    );
    final data = res.data?['data'];
    if (data is Map<String, dynamic>) {
      return data['categoryId'] as String?;
    }
    return null;
  }
}
```

- [ ] **Step 3: Failing repo test** `test/features/categorization/categorization_repository_test.dart`:
```dart
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/categorization/data/categorization_data_source.dart';
import 'package:aifb/features/categorization/data/categorization_repository.dart';
import 'package:aifb/features/categorization/data/models/rule_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDs extends Mock implements CategorizationDataSource {}

void main() {
  late _MockDs ds;
  late CategorizationRepository repo;

  setUp(() {
    ds = _MockDs();
    repo = CategorizationRepository(ds);
  });

  test('list returns Ok with rules', () async {
    when(ds.list).thenAnswer((_) async => const [
          RuleModel(id: 'r1', keyword: 'magnum', categoryId: 'c1', categoryName: 'Еда'),
        ]);
    final result = await repo.list();
    expect(result, isA<Ok<List<RuleModel>>>());
    expect((result as Ok<List<RuleModel>>).value.single.keyword, 'magnum');
  });

  test('list maps error to Err', () async {
    when(ds.list).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/categorization/rules')),
    );
    final result = await repo.list();
    expect(result, isA<Err<List<RuleModel>>>());
  });
}
```
Run `cd frontend && flutter test test/features/categorization/categorization_repository_test.dart` → FAIL.

- [ ] **Step 4: Repository** `lib/features/categorization/data/categorization_repository.dart`:
```dart
import 'package:aifb/core/errors/error_mapper.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/categorization/data/categorization_data_source.dart';
import 'package:aifb/features/categorization/data/models/rule_model.dart';

class CategorizationRepository {
  CategorizationRepository(this._ds);
  final CategorizationDataSource _ds;

  Future<Result<List<RuleModel>>> list() => _guard(_ds.list);

  Future<Result<RuleModel>> create({required String keyword, required String categoryId}) =>
      _guard(() => _ds.create({'keyword': keyword, 'categoryId': categoryId}));

  Future<Result<void>> delete(String id) => _guard(() => _ds.delete(id));

  Future<Result<String?>> suggest({required String note, required String type}) =>
      _guard(() => _ds.suggest(note, type));

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

- [ ] **Step 5: Providers** `lib/features/categorization/presentation/providers/categorization_providers.dart`:
```dart
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/core/network/dio_client.dart';
import 'package:aifb/features/categorization/data/categorization_data_source.dart';
import 'package:aifb/features/categorization/data/categorization_repository.dart';
import 'package:aifb/features/categorization/data/models/rule_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categorizationDataSourceProvider = Provider<CategorizationDataSource>((ref) {
  return CategorizationDataSource(ref.watch(dioProvider));
});

final categorizationRepositoryProvider = Provider<CategorizationRepository>((ref) {
  return CategorizationRepository(ref.watch(categorizationDataSourceProvider));
});

final rulesProvider = FutureProvider.autoDispose<List<RuleModel>>((ref) async {
  final result = await ref.watch(categorizationRepositoryProvider).list();
  return switch (result) {
    Ok<List<RuleModel>>(value: final v) => v,
    Err<List<RuleModel>>(failure: final f) => throw Exception(f.toString()),
  };
});
```

- [ ] **Step 6: Экран** `lib/features/categorization/presentation/pages/rules_page.dart`:
```dart
import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/features/categorization/presentation/providers/categorization_providers.dart';
import 'package:aifb/features/transactions/presentation/providers/finance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RulesPage extends ConsumerWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(rulesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Правила категоризации')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Новое правило'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(rulesProvider.future),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [const SizedBox(height: 80), Center(child: Text('Ошибка: $e'))],
          ),
          data: (rules) {
            if (rules.isEmpty) {
              return ListView(
                children: const [SizedBox(height: 120), Center(child: Text('Правил пока нет'))],
              );
            }
            return ListView.separated(
              itemCount: rules.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = rules[i];
                return ListTile(
                  title: Text('«${r.keyword}» → ${r.categoryName}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ref.read(categorizationRepositoryProvider).delete(r.id);
                      ref.invalidate(rulesProvider);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final keyword = TextEditingController();
    String? categoryId;
    final catsAsync = await ref.read(categoriesProvider('EXPENSE').future);
    if (!context.mounted) return;
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Новое правило'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyword,
                decoration: const InputDecoration(labelText: 'Ключевое слово'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: categoryId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Категория'),
                items: catsAsync
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => categoryId = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            FilledButton(
              onPressed: () async {
                if (keyword.text.trim().isEmpty || categoryId == null) return;
                await ref.read(categorizationRepositoryProvider)
                    .create(keyword: keyword.text.trim(), categoryId: categoryId!);
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
    if (created ?? false) ref.invalidate(rulesProvider);
  }
}
```
(`categoriesProvider` — существующий FutureProvider.family<List<CategoryModel>, String?> личных категорий; используется тип EXPENSE для выбора. `Scope` импорт не нужен здесь — убрать, если анализатор пожалуется на неиспользуемый импорт; оставлено на случай, если понадобится. ВАЖНО: если `import scope.dart` не используется — удалить его, чтобы пройти `unused_import`.)

- [ ] **Step 7: Маршрут.** In `lib/app/router/routes.dart` App shell add `static const rules = _Route('rules', '/rules');`. In `lib/app/router/app_router.dart` add import (relative) `import '../../features/categorization/presentation/pages/rules_page.dart';` and GoRoute:
```dart
      GoRoute(
        path: AppRoutes.rules.path,
        name: AppRoutes.rules.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const RulesPage(),
        ),
      ),
```

- [ ] **Step 8: Подсказка в форме операции.** In `lib/features/transactions/presentation/widgets/transaction_form_sheet.dart`: READ it. The note field is `_note` (TextEditingController), category state `_categoryId`, type `_type`. Add an `onEditingComplete`/suffix button to the note `TextField` that calls suggest and prefills `_categoryId` if empty. Concretely, add to the note `TextField`:
```dart
            decoration: InputDecoration(
              labelText: 'Заметка (необязательно)',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.auto_awesome),
                tooltip: 'Подобрать категорию',
                onPressed: () async {
                  final result = await ref.read(categorizationRepositoryProvider)
                      .suggest(note: _note.text, type: _type);
                  if (result is Ok<String?> && result.value != null) {
                    setState(() => _categoryId = result.value);
                  }
                },
              ),
            ),
```
Add imports: `package:aifb/core/network/api_result.dart` (for `Ok`) and `package:aifb/features/categorization/presentation/providers/categorization_providers.dart`. (The existing `_note` TextField currently has a `const InputDecoration`; replace it with the non-const version above. Keep the rest of the form intact.)

- [ ] **Step 9: Анализ + тесты + commit**
```bash
cd frontend && flutter analyze lib && flutter test
git add frontend/lib/core/network/api_endpoints.dart frontend/lib/features/categorization frontend/lib/features/transactions/presentation/widgets/transaction_form_sheet.dart frontend/lib/app/router/routes.dart frontend/lib/app/router/app_router.dart frontend/test/features/categorization
git commit -m "feat(frontend): фича categorization — правила + подсказка категории в форме + маршрут"
```
Expected: analyze 0 errors/warnings (info ок); все тесты passed.

---

## Self-review (выполнено при написании плана)

- **Покрытие спеки:** `categorization_rules` (V12, личные, уникальный keyword); CRUD правил с валидацией категории (личная/системная) и 404 на чужое; `resolve`/`suggest` (подстрока без регистра, фильтр по типу, самое длинное слово); авто-присвоение при создании личной операции без категории (нет правил → 400; семейная без категории → 400; явная категория не перетирается); фронт-фича `categorization` (экран правил + подсказка в форме). Все секции спеки покрыты.
- **Плейсхолдеры:** нет — полный код либо точечные правки с указанием места; обновление существующих тестов не требуется (они передают categoryId; снятие `@NotNull` не ломает их).
- **Согласованность типов:** `CategorizationService.list/create/update/delete/resolve(userId,note,type)→Optional<UUID>` согласованы между сервисом, контроллером (`suggest` использует `resolve`) и `TransactionService`. `RuleResponse`/`Suggest*` DTO, `findForMatching(userId,type)` совпадают. `CategoryRepository.findVisibleByIdPersonal`, `Category.getType()/getName()`, `CategoryType` — существующие. На фронте `categoriesProvider('EXPENSE')` и `Ok<String?>` из `Result` — существующие типы.
- **Заметка:** авто-присвоение только для личных операций (`shared=false`); семейная без категории → доменная ошибка. Это согласуется со спекой (личные правила → личные/системные категории).
