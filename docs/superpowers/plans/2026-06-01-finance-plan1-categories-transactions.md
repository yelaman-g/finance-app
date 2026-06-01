# План 1 — Backend: Категории + Транзакции

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Реализовать серверную часть категорий (системные + пользовательские, мягкое удаление) и транзакций (доходы/расходы с валидацией типов, фильтрацией и пагинацией) с интеграционными тестами на Testcontainers.

**Architecture:** Новые feature-модули `finance/category` и `finance/transaction` строятся строго по образцу модуля `auth`: пакеты `domain` / `repository` / `service` / `api` / `api/dto`; сущности наследуют `BaseEntity` (UUID PK, аудит, optimistic lock); ответы заворачиваются в `ApiResponse` / `PageResponse`; ошибки бросаются доменными исключениями (`NotFoundException`, `ConflictException`, `ForbiddenException`, `DomainException`) и транслируются `GlobalExceptionHandler`. Привязка к пользователю — через `UUID userId` (берётся из `@CurrentUser AuthPrincipal`), без загрузки сущности `User`.

**Tech Stack:** Spring Boot 3.3.5, Java 21, Spring Data JPA, PostgreSQL, Flyway, Jakarta Validation; тесты — JUnit 5 + Spring Boot Test + Testcontainers (PostgreSQL) + MockMvc.

---

## Структура файлов

**Изменяемые:**
- `backend/build.gradle` — добавить тестовые зависимости Testcontainers.

**Создаваемые — миграции:**
- `backend/src/main/resources/db/migration/V4__categories.sql`
- `backend/src/main/resources/db/migration/V5__transactions.sql`

**Создаваемые — модуль `category`:**
- `.../finance/category/domain/CategoryType.java` — enum `INCOME` / `EXPENSE` (общий для категорий и транзакций).
- `.../finance/category/domain/Category.java` — JPA-сущность.
- `.../finance/category/repository/CategoryRepository.java`
- `.../finance/category/service/CategoryService.java`
- `.../finance/category/api/CategoryController.java`
- `.../finance/category/api/dto/CategoryResponse.java`
- `.../finance/category/api/dto/CreateCategoryRequest.java`
- `.../finance/category/api/dto/UpdateCategoryRequest.java`

**Создаваемые — модуль `transaction`:**
- `.../finance/transaction/domain/Transaction.java`
- `.../finance/transaction/repository/TransactionRepository.java`
- `.../finance/transaction/service/TransactionService.java`
- `.../finance/transaction/api/TransactionController.java`
- `.../finance/transaction/api/dto/TransactionResponse.java`
- `.../finance/transaction/api/dto/CreateTransactionRequest.java`
- `.../finance/transaction/api/dto/UpdateTransactionRequest.java`

**Создаваемые — тестовая инфраструктура и тесты** (`backend/src/test/java/com/aifb/platform/...`):
- `support/AbstractIntegrationTest.java` — базовый класс (Testcontainers + MockMvc).
- `support/TestAuth.java` — создание пользователя и выпуск JWT.
- `finance/category/CategoryServiceIT.java`
- `finance/category/CategoryApiIT.java`
- `finance/transaction/TransactionServiceIT.java`
- `finance/transaction/TransactionApiIT.java`

Базовый Java-пакет: `com.aifb.platform`. Полный путь к исходникам — `backend/src/main/java/com/aifb/platform/`, к тестам — `backend/src/test/java/com/aifb/platform/`.

---

## Task 1: Тестовая инфраструктура (Testcontainers)

**Files:**
- Modify: `backend/build.gradle`
- Create: `backend/src/test/java/com/aifb/platform/support/AbstractIntegrationTest.java`
- Create: `backend/src/test/java/com/aifb/platform/support/TestAuth.java`
- Create: `backend/src/test/java/com/aifb/platform/SmokeContextIT.java`

- [ ] **Step 1: Добавить тестовые зависимости в `build.gradle`**

В блоке `dependencies` после строки `testImplementation 'org.springframework.security:spring-security-test'` добавить:

```groovy
    testImplementation 'org.springframework.boot:spring-boot-testcontainers'
    testImplementation 'org.testcontainers:junit-jupiter'
    testImplementation 'org.testcontainers:postgresql'
```

(Версии не указываются — управляются BOM Spring Boot 3.3.5.)

- [ ] **Step 2: Создать базовый класс интеграционных тестов**

Create `backend/src/test/java/com/aifb/platform/support/AbstractIntegrationTest.java`:

```java
package com.aifb.platform.support;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Поднимает полный контекст приложения на одноразовом PostgreSQL-контейнере.
 * Flyway прогоняет реальные миграции, поэтому ddl-auto=validate проходит.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
public abstract class AbstractIntegrationTest {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer<?> POSTGRES =
            new PostgreSQLContainer<>("postgres:16");

    @Autowired
    protected MockMvc mockMvc;
}
```

- [ ] **Step 3: Создать хелпер аутентификации**

Create `backend/src/test/java/com/aifb/platform/support/TestAuth.java`:

```java
package com.aifb.platform.support;

import com.aifb.platform.auth.domain.Role;
import com.aifb.platform.auth.domain.User;
import com.aifb.platform.auth.repository.UserRepository;
import com.aifb.platform.common.security.jwt.JwtService;
import org.springframework.stereotype.Component;

import java.util.Set;
import java.util.UUID;

/** Создаёт пользователя в БД и выпускает для него валидный access-JWT. */
@Component
public class TestAuth {

    private final UserRepository userRepository;
    private final JwtService jwtService;

    public TestAuth(UserRepository userRepository, JwtService jwtService) {
        this.userRepository = userRepository;
        this.jwtService = jwtService;
    }

    public record AuthedUser(UUID id, String email, String bearer) {}

    public AuthedUser createUser() {
        String email = "user-" + UUID.randomUUID() + "@example.com";
        User user = new User(email, "Test User", "x", Set.of(Role.USER));
        userRepository.saveAndFlush(user);
        String token = jwtService.issueAccessToken(
                user.getId(), email, Set.of("USER"), 0);
        return new AuthedUser(user.getId(), email, "Bearer " + token);
    }
}
```

- [ ] **Step 4: Написать smoke-тест поднятия контекста**

Create `backend/src/test/java/com/aifb/platform/SmokeContextIT.java`:

```java
package com.aifb.platform;

import com.aifb.platform.support.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import com.aifb.platform.support.TestAuth;

import static org.assertj.core.api.Assertions.assertThat;

class SmokeContextIT extends AbstractIntegrationTest {

    @Autowired
    TestAuth testAuth;

    @Test
    void contextLoadsAndCanMintToken() {
        TestAuth.AuthedUser u = testAuth.createUser();
        assertThat(u.bearer()).startsWith("Bearer ");
        assertThat(u.id()).isNotNull();
    }
}
```

- [ ] **Step 5: Запустить smoke-тест — убедиться, что проходит**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test --tests 'com.aifb.platform.SmokeContextIT'
```
Expected: `BUILD SUCCESSFUL`, 1 тест passed. (Требуется запущенный Docker — Testcontainers поднимет `postgres:16`.)

- [ ] **Step 6: Commit**

```bash
git add backend/build.gradle backend/src/test/java/com/aifb/platform/support backend/src/test/java/com/aifb/platform/SmokeContextIT.java
git commit -m "test: инфраструктура интеграционных тестов на Testcontainers"
```

---

## Task 2: Категория — миграция, enum, сущность, репозиторий

**Files:**
- Create: `backend/src/main/resources/db/migration/V4__categories.sql`
- Create: `.../finance/category/domain/CategoryType.java`
- Create: `.../finance/category/domain/Category.java`
- Create: `.../finance/category/repository/CategoryRepository.java`

- [ ] **Step 1: Создать миграцию V4**

Create `backend/src/main/resources/db/migration/V4__categories.sql`:

```sql
CREATE TABLE categories (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(80) NOT NULL,
    type VARCHAR(10) NOT NULL,
    icon VARCHAR(40),
    color VARCHAR(9),
    is_system BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT chk_categories_type CHECK (type IN ('INCOME', 'EXPENSE'))
);

-- Уникальность имени в рамках (владелец, тип) среди НЕудалённых.
CREATE UNIQUE INDEX uk_categories_user_name_type
    ON categories (user_id, lower(name), type)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_categories_visible
    ON categories (user_id, type) WHERE deleted_at IS NULL;

-- Системный набор категорий (user_id IS NULL, общий для всех).
INSERT INTO categories (id, user_id, name, type, icon, color, is_system) VALUES
    (gen_random_uuid(), NULL, 'Еда',          'EXPENSE', 'restaurant',   '#FF7043', TRUE),
    (gen_random_uuid(), NULL, 'Транспорт',    'EXPENSE', 'directions_car','#42A5F5', TRUE),
    (gen_random_uuid(), NULL, 'Жильё',        'EXPENSE', 'home',         '#8D6E63', TRUE),
    (gen_random_uuid(), NULL, 'Развлечения',  'EXPENSE', 'movie',        '#AB47BC', TRUE),
    (gen_random_uuid(), NULL, 'Здоровье',     'EXPENSE', 'favorite',     '#EF5350', TRUE),
    (gen_random_uuid(), NULL, 'Покупки',      'EXPENSE', 'shopping_bag', '#26A69A', TRUE),
    (gen_random_uuid(), NULL, 'Связь',        'EXPENSE', 'wifi',         '#5C6BC0', TRUE),
    (gen_random_uuid(), NULL, 'Прочее',       'EXPENSE', 'category',     '#78909C', TRUE),
    (gen_random_uuid(), NULL, 'Зарплата',     'INCOME',  'payments',     '#66BB6A', TRUE),
    (gen_random_uuid(), NULL, 'Подработка',   'INCOME',  'work',         '#9CCC65', TRUE),
    (gen_random_uuid(), NULL, 'Подарки',      'INCOME',  'redeem',       '#EC407A', TRUE),
    (gen_random_uuid(), NULL, 'Инвестиции',   'INCOME',  'trending_up',  '#26C6DA', TRUE),
    (gen_random_uuid(), NULL, 'Прочее',       'INCOME',  'category',     '#78909C', TRUE);
```

- [ ] **Step 2: Создать enum `CategoryType`**

Create `.../finance/category/domain/CategoryType.java`:

```java
package com.aifb.platform.finance.category.domain;

public enum CategoryType {
    INCOME,
    EXPENSE
}
```

- [ ] **Step 3: Создать сущность `Category`**

Create `.../finance/category/domain/Category.java`:

```java
package com.aifb.platform.finance.category.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "categories")
public class Category extends BaseEntity {

    @Column(name = "user_id")
    private UUID userId; // null => системная категория

    @Column(nullable = false, length = 80)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private CategoryType type;

    @Column(length = 40)
    private String icon;

    @Column(length = 9)
    private String color;

    @Column(name = "is_system", nullable = false)
    private boolean system;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    protected Category() {
    }

    /** Конструктор пользовательской (несистемной) категории. */
    public Category(UUID userId, String name, CategoryType type, String icon, String color) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.name = name;
        this.type = type;
        this.icon = icon;
        this.color = color;
        this.system = false;
    }

    public UUID getUserId() { return userId; }
    public String getName() { return name; }
    public CategoryType getType() { return type; }
    public String getIcon() { return icon; }
    public String getColor() { return color; }
    public boolean isSystem() { return system; }
    public Instant getDeletedAt() { return deletedAt; }
    public boolean isDeleted() { return deletedAt != null; }

    public void setName(String name) { this.name = name; }
    public void setIcon(String icon) { this.icon = icon; }
    public void setColor(String color) { this.color = color; }

    public void softDelete(Instant when) { this.deletedAt = when; }
}
```

- [ ] **Step 4: Создать репозиторий `CategoryRepository`**

Create `.../finance/category/repository/CategoryRepository.java`:

```java
package com.aifb.platform.finance.category.repository;

import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.domain.CategoryType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CategoryRepository extends JpaRepository<Category, UUID> {

    /** Видимые пользователю категории: системные + его собственные, без удалённых. */
    @Query("""
            select c from Category c
            where c.deletedAt is null
              and (c.userId is null or c.userId = :userId)
              and (:type is null or c.type = :type)
            order by c.system desc, c.name asc
            """)
    List<Category> findVisible(@Param("userId") UUID userId,
                               @Param("type") CategoryType type);

    /** Конкретная видимая (системная или своя) неудалённая категория по id. */
    @Query("""
            select c from Category c
            where c.id = :id
              and c.deletedAt is null
              and (c.userId is null or c.userId = :userId)
            """)
    Optional<Category> findVisibleByIdForUser(@Param("id") UUID id,
                                              @Param("userId") UUID userId);

    boolean existsByUserIdAndTypeAndNameIgnoreCaseAndDeletedAtIsNull(
            UUID userId, CategoryType type, String name);

    List<Category> findByIdInAndDeletedAtIsNull(Collection<UUID> ids);
}
```

- [ ] **Step 5: Запустить приложение/тест для проверки валидации схемы**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test --tests 'com.aifb.platform.SmokeContextIT'
```
Expected: `BUILD SUCCESSFUL`. Контекст поднимается, Flyway применяет V4, Hibernate `validate` подтверждает соответствие сущности `Category` таблице `categories`.

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/resources/db/migration/V4__categories.sql backend/src/main/java/com/aifb/platform/finance/category/domain backend/src/main/java/com/aifb/platform/finance/category/repository
git commit -m "feat(category): миграция, сущность, enum и репозиторий категорий"
```

---

## Task 3: Категория — DTO, сервис, тесты сервиса

**Files:**
- Create: `.../finance/category/api/dto/CategoryResponse.java`
- Create: `.../finance/category/api/dto/CreateCategoryRequest.java`
- Create: `.../finance/category/api/dto/UpdateCategoryRequest.java`
- Create: `.../finance/category/service/CategoryService.java`
- Test: `backend/src/test/java/com/aifb/platform/finance/category/CategoryServiceIT.java`

- [ ] **Step 1: Создать DTO ответа**

Create `.../finance/category/api/dto/CategoryResponse.java`:

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
        boolean system) {

    public static CategoryResponse from(Category c) {
        return new CategoryResponse(
                c.getId(),
                c.getName(),
                c.getType().name(),
                c.getIcon(),
                c.getColor(),
                c.isSystem());
    }
}
```

- [ ] **Step 2: Создать DTO запросов**

Create `.../finance/category/api/dto/CreateCategoryRequest.java`:

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
        @Size(max = 9) String color) {
}
```

Create `.../finance/category/api/dto/UpdateCategoryRequest.java`:

```java
package com.aifb.platform.finance.category.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateCategoryRequest(
        @NotBlank @Size(max = 80) String name,
        @Size(max = 40) String icon,
        @Size(max = 9) String color) {
}
```

- [ ] **Step 3: Написать падающий тест сервиса**

Create `backend/src/test/java/com/aifb/platform/finance/category/CategoryServiceIT.java`:

```java
package com.aifb.platform.finance.category;

import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.category.api.dto.CategoryResponse;
import com.aifb.platform.finance.category.api.dto.CreateCategoryRequest;
import com.aifb.platform.finance.category.api.dto.UpdateCategoryRequest;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.repository.CategoryRepository;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CategoryServiceIT extends AbstractIntegrationTest {

    @Autowired CategoryService service;
    @Autowired CategoryRepository repository;
    @Autowired TestAuth testAuth;

    @Test
    void listReturnsSystemCategoriesForNewUser() {
        UUID userId = testAuth.createUser().id();
        List<CategoryResponse> expense = service.list(userId, CategoryType.EXPENSE);
        assertThat(expense).isNotEmpty();
        assertThat(expense).allMatch(c -> c.type().equals("EXPENSE"));
        assertThat(expense).anyMatch(CategoryResponse::system);
    }

    @Test
    void createAddsUserCategoryVisibleOnlyToOwner() {
        UUID owner = testAuth.createUser().id();
        UUID other = testAuth.createUser().id();

        CategoryResponse created = service.create(owner,
                new CreateCategoryRequest("Кафе", CategoryType.EXPENSE, "coffee", "#FFAA00"));

        assertThat(created.system()).isFalse();
        assertThat(service.list(owner, CategoryType.EXPENSE))
                .anyMatch(c -> c.id().equals(created.id()));
        assertThat(service.list(other, CategoryType.EXPENSE))
                .noneMatch(c -> c.id().equals(created.id()));
    }

    @Test
    void createRejectsDuplicateActiveName() {
        UUID owner = testAuth.createUser().id();
        service.create(owner, new CreateCategoryRequest("Кафе", CategoryType.EXPENSE, null, null));
        assertThatThrownBy(() -> service.create(owner,
                new CreateCategoryRequest("кафе", CategoryType.EXPENSE, null, null)))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void updateChangesOwnedCategory() {
        UUID owner = testAuth.createUser().id();
        CategoryResponse created = service.create(owner,
                new CreateCategoryRequest("Кафе", CategoryType.EXPENSE, null, null));
        CategoryResponse updated = service.update(owner, created.id(),
                new UpdateCategoryRequest("Кофейни", "coffee", "#112233"));
        assertThat(updated.name()).isEqualTo("Кофейни");
        assertThat(updated.icon()).isEqualTo("coffee");
    }

    @Test
    void updateSystemCategoryForbidden() {
        UUID owner = testAuth.createUser().id();
        UUID systemId = repository.findVisible(owner, CategoryType.EXPENSE).stream()
                .filter(c -> c.isSystem()).findFirst().orElseThrow().getId();
        assertThatThrownBy(() -> service.update(owner, systemId,
                new UpdateCategoryRequest("Hacked", null, null)))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void deleteSoftDeletesAndHidesFromList() {
        UUID owner = testAuth.createUser().id();
        CategoryResponse created = service.create(owner,
                new CreateCategoryRequest("Кафе", CategoryType.EXPENSE, null, null));
        service.delete(owner, created.id());

        assertThat(service.list(owner, CategoryType.EXPENSE))
                .noneMatch(c -> c.id().equals(created.id()));
        assertThat(repository.findById(created.id()).orElseThrow().isDeleted()).isTrue();
        // Имя освобождается для повторного создания.
        assertThat(service.create(owner,
                new CreateCategoryRequest("Кафе", CategoryType.EXPENSE, null, null)).id())
                .isNotNull();
    }

    @Test
    void updateOtherUsersCategoryNotFound() {
        UUID owner = testAuth.createUser().id();
        UUID other = testAuth.createUser().id();
        CategoryResponse created = service.create(owner,
                new CreateCategoryRequest("Кафе", CategoryType.EXPENSE, null, null));
        assertThatThrownBy(() -> service.update(other, created.id(),
                new UpdateCategoryRequest("X", null, null)))
                .isInstanceOf(NotFoundException.class);
    }
}
```

- [ ] **Step 4: Запустить тест — убедиться, что НЕ компилируется/падает**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test --tests 'com.aifb.platform.finance.category.CategoryServiceIT'
```
Expected: FAIL — компиляция падает, т.к. `CategoryService` ещё не создан.

- [ ] **Step 5: Создать `CategoryService`**

Create `.../finance/category/service/CategoryService.java`:

```java
package com.aifb.platform.finance.category.service;

import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.category.api.dto.CategoryResponse;
import com.aifb.platform.finance.category.api.dto.CreateCategoryRequest;
import com.aifb.platform.finance.category.api.dto.UpdateCategoryRequest;
import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.repository.CategoryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class CategoryService {

    private final CategoryRepository repository;

    public CategoryService(CategoryRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public List<CategoryResponse> list(UUID userId, CategoryType type) {
        return repository.findVisible(userId, type).stream()
                .map(CategoryResponse::from)
                .toList();
    }

    @Transactional
    public CategoryResponse create(UUID userId, CreateCategoryRequest req) {
        if (repository.existsByUserIdAndTypeAndNameIgnoreCaseAndDeletedAtIsNull(
                userId, req.type(), req.name())) {
            throw new ConflictException("Категория с таким именем уже существует");
        }
        Category category = new Category(userId, req.name(), req.type(), req.icon(), req.color());
        return CategoryResponse.from(repository.save(category));
    }

    @Transactional
    public CategoryResponse update(UUID userId, UUID id, UpdateCategoryRequest req) {
        Category category = ownedCategory(userId, id);
        category.setName(req.name());
        category.setIcon(req.icon());
        category.setColor(req.color());
        return CategoryResponse.from(repository.save(category));
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        Category category = ownedCategory(userId, id);
        category.softDelete(Instant.now());
        repository.save(category);
    }

    private Category ownedCategory(UUID userId, UUID id) {
        Category category = repository.findById(id)
                .filter(c -> !c.isDeleted())
                .orElseThrow(() -> new NotFoundException("Категория не найдена"));
        if (category.isSystem()) {
            throw new ForbiddenException("Системные категории нельзя изменять");
        }
        if (!userId.equals(category.getUserId())) {
            throw new NotFoundException("Категория не найдена");
        }
        return category;
    }
}
```

- [ ] **Step 6: Запустить тест — убедиться, что проходит**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test --tests 'com.aifb.platform.finance.category.CategoryServiceIT'
```
Expected: `BUILD SUCCESSFUL`, 7 тестов passed.

- [ ] **Step 7: Commit**

```bash
git add backend/src/main/java/com/aifb/platform/finance/category/api backend/src/main/java/com/aifb/platform/finance/category/service backend/src/test/java/com/aifb/platform/finance/category/CategoryServiceIT.java
git commit -m "feat(category): сервис категорий с тестами (создание, правка, мягкое удаление, изоляция)"
```

---

## Task 4: Категория — контроллер и web-тесты

**Files:**
- Create: `.../finance/category/api/CategoryController.java`
- Test: `backend/src/test/java/com/aifb/platform/finance/category/CategoryApiIT.java`

- [ ] **Step 1: Написать падающий web-тест**

Create `backend/src/test/java/com/aifb/platform/finance/category/CategoryApiIT.java`:

```java
package com.aifb.platform.finance.category;

import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;

import static org.hamcrest.Matchers.greaterThan;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class CategoryApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;

    @Test
    void listRequiresAuth() throws Exception {
        mockMvc.perform(get("/api/v1/categories").param("type", "EXPENSE"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void listReturnsSystemCategories() throws Exception {
        String bearer = testAuth.createUser().bearer();
        mockMvc.perform(get("/api/v1/categories")
                        .param("type", "EXPENSE")
                        .header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()", greaterThan(0)))
                .andExpect(jsonPath("$.data[0].type").value("EXPENSE"));
    }

    @Test
    void createReturnsCreatedCategory() throws Exception {
        String bearer = testAuth.createUser().bearer();
        mockMvc.perform(post("/api/v1/categories")
                        .header(HttpHeaders.AUTHORIZATION, bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Кафе","type":"EXPENSE","icon":"coffee","color":"#FFAA00"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Кафе"))
                .andExpect(jsonPath("$.data.system").value(false));
    }

    @Test
    void createRejectsBlankName() throws Exception {
        String bearer = testAuth.createUser().bearer();
        mockMvc.perform(post("/api/v1/categories")
                        .header(HttpHeaders.AUTHORIZATION, bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"","type":"EXPENSE"}
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
  ./gradlew test --tests 'com.aifb.platform.finance.category.CategoryApiIT'
```
Expected: FAIL — нет контроллера, эндпоинт `/api/v1/categories` отдаёт 401/403 на всех (включая create), тесты на 200 падают.

- [ ] **Step 3: Создать `CategoryController`**

Create `.../finance/category/api/CategoryController.java`:

```java
package com.aifb.platform.finance.category.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.finance.category.api.dto.CategoryResponse;
import com.aifb.platform.finance.category.api.dto.CreateCategoryRequest;
import com.aifb.platform.finance.category.api.dto.UpdateCategoryRequest;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
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
@RequestMapping("/api/v1/categories")
public class CategoryController {

    private final CategoryService service;

    public CategoryController(CategoryService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<List<CategoryResponse>> list(
            @CurrentUser AuthPrincipal principal,
            @RequestParam(required = false) CategoryType type) {
        return ApiResponse.ok(service.list(principal.userId(), type));
    }

    @PostMapping
    public ApiResponse<CategoryResponse> create(
            @CurrentUser AuthPrincipal principal,
            @Valid @RequestBody CreateCategoryRequest request) {
        return ApiResponse.ok(service.create(principal.userId(), request));
    }

    @PutMapping("/{id}")
    public ApiResponse<CategoryResponse> update(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id,
            @Valid @RequestBody UpdateCategoryRequest request) {
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

- [ ] **Step 4: Зарегистрировать `/api/v1/categories/**` как защищённый — проверить SecurityConfig**

Открыть `.../config/SecurityConfig.java`. Изменений НЕ требуется: правило `.anyRequest().authenticated()` уже закрывает все новые эндпоинты, в `PUBLIC_ENDPOINTS` категории не добавляем. Этот шаг — только подтверждение (не править файл).

- [ ] **Step 5: Запустить тест — убедиться, что проходит**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test --tests 'com.aifb.platform.finance.category.CategoryApiIT'
```
Expected: `BUILD SUCCESSFUL`, 4 теста passed.

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/com/aifb/platform/finance/category/api/CategoryController.java backend/src/test/java/com/aifb/platform/finance/category/CategoryApiIT.java
git commit -m "feat(category): REST-контроллер категорий с web-тестами"
```

---

## Task 5: Транзакция — миграция, сущность, репозиторий

**Files:**
- Create: `backend/src/main/resources/db/migration/V5__transactions.sql`
- Create: `.../finance/transaction/domain/Transaction.java`
- Create: `.../finance/transaction/repository/TransactionRepository.java`

- [ ] **Step 1: Создать миграцию V5**

Create `backend/src/main/resources/db/migration/V5__transactions.sql`:

```sql
CREATE TABLE transactions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id),
    type VARCHAR(10) NOT NULL,
    amount NUMERIC(15,2) NOT NULL,
    note VARCHAR(255),
    occurred_on DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT chk_transactions_type CHECK (type IN ('INCOME', 'EXPENSE')),
    CONSTRAINT chk_transactions_amount_positive CHECK (amount > 0)
);

CREATE INDEX idx_transactions_user_date ON transactions (user_id, occurred_on DESC);
CREATE INDEX idx_transactions_user_category ON transactions (user_id, category_id);
```

- [ ] **Step 2: Создать сущность `Transaction`**

Create `.../finance/transaction/domain/Transaction.java`:

```java
package com.aifb.platform.finance.transaction.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import com.aifb.platform.finance.category.domain.CategoryType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "transactions")
public class Transaction extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "category_id", nullable = false)
    private UUID categoryId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private CategoryType type;

    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal amount;

    @Column(length = 255)
    private String note;

    @Column(name = "occurred_on", nullable = false)
    private LocalDate occurredOn;

    protected Transaction() {
    }

    public Transaction(UUID userId, UUID categoryId, CategoryType type,
                       BigDecimal amount, String note, LocalDate occurredOn) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.categoryId = categoryId;
        this.type = type;
        this.amount = amount;
        this.note = note;
        this.occurredOn = occurredOn;
    }

    public UUID getUserId() { return userId; }
    public UUID getCategoryId() { return categoryId; }
    public CategoryType getType() { return type; }
    public BigDecimal getAmount() { return amount; }
    public String getNote() { return note; }
    public LocalDate getOccurredOn() { return occurredOn; }

    public void setCategoryId(UUID categoryId) { this.categoryId = categoryId; }
    public void setType(CategoryType type) { this.type = type; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
    public void setNote(String note) { this.note = note; }
    public void setOccurredOn(LocalDate occurredOn) { this.occurredOn = occurredOn; }
}
```

- [ ] **Step 3: Создать репозиторий `TransactionRepository`**

Create `.../finance/transaction/repository/TransactionRepository.java`:

```java
package com.aifb.platform.finance.transaction.repository;

import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.transaction.domain.Transaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

public interface TransactionRepository extends JpaRepository<Transaction, UUID> {

    @Query("""
            select t from Transaction t
            where t.userId = :userId
              and (:from is null or t.occurredOn >= :from)
              and (:to is null or t.occurredOn <= :to)
              and (:type is null or t.type = :type)
              and (:categoryId is null or t.categoryId = :categoryId)
            """)
    Page<Transaction> search(@Param("userId") UUID userId,
                             @Param("from") LocalDate from,
                             @Param("to") LocalDate to,
                             @Param("type") CategoryType type,
                             @Param("categoryId") UUID categoryId,
                             Pageable pageable);

    Optional<Transaction> findByIdAndUserId(UUID id, UUID userId);

    boolean existsByCategoryId(UUID categoryId);
}
```

- [ ] **Step 4: Проверить валидацию схемы**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test --tests 'com.aifb.platform.SmokeContextIT'
```
Expected: `BUILD SUCCESSFUL`. Flyway применяет V5, Hibernate `validate` подтверждает соответствие сущности `Transaction`.

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/resources/db/migration/V5__transactions.sql backend/src/main/java/com/aifb/platform/finance/transaction/domain backend/src/main/java/com/aifb/platform/finance/transaction/repository
git commit -m "feat(transaction): миграция, сущность и репозиторий транзакций"
```

---

## Task 6: Транзакция — DTO, сервис, тесты сервиса

**Files:**
- Create: `.../finance/transaction/api/dto/TransactionResponse.java`
- Create: `.../finance/transaction/api/dto/CreateTransactionRequest.java`
- Create: `.../finance/transaction/api/dto/UpdateTransactionRequest.java`
- Create: `.../finance/transaction/service/TransactionService.java`
- Test: `backend/src/test/java/com/aifb/platform/finance/transaction/TransactionServiceIT.java`

- [ ] **Step 1: Создать DTO ответа**

Create `.../finance/transaction/api/dto/TransactionResponse.java`:

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
        Instant createdAt) {

    public static TransactionResponse from(Transaction t, Category category) {
        return new TransactionResponse(
                t.getId(),
                t.getCategoryId(),
                category == null ? null : category.getName(),
                category == null ? null : category.getColor(),
                category == null ? null : category.getIcon(),
                t.getType().name(),
                t.getAmount(),
                t.getNote(),
                t.getOccurredOn(),
                t.getCreatedAt());
    }
}
```

- [ ] **Step 2: Создать DTO запросов**

Create `.../finance/transaction/api/dto/CreateTransactionRequest.java`:

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
        @NotNull UUID categoryId,
        @NotNull CategoryType type,
        @NotNull @DecimalMin(value = "0.01") @Digits(integer = 13, fraction = 2) BigDecimal amount,
        @Size(max = 255) String note,
        @NotNull @PastOrPresent LocalDate occurredOn) {
}
```

Create `.../finance/transaction/api/dto/UpdateTransactionRequest.java`:

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

public record UpdateTransactionRequest(
        @NotNull UUID categoryId,
        @NotNull CategoryType type,
        @NotNull @DecimalMin(value = "0.01") @Digits(integer = 13, fraction = 2) BigDecimal amount,
        @Size(max = 255) String note,
        @NotNull @PastOrPresent LocalDate occurredOn) {
}
```

- [ ] **Step 3: Написать падающий тест сервиса**

Create `backend/src/test/java/com/aifb/platform/finance/transaction/TransactionServiceIT.java`:

```java
package com.aifb.platform.finance.transaction;

import com.aifb.platform.common.api.PageResponse;
import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.category.api.dto.CategoryResponse;
import com.aifb.platform.finance.category.api.dto.CreateCategoryRequest;
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

class TransactionServiceIT extends AbstractIntegrationTest {

    @Autowired TransactionService service;
    @Autowired CategoryService categoryService;
    @Autowired TestAuth testAuth;

    private UUID expenseCategory(UUID userId) {
        return categoryService.list(userId, CategoryType.EXPENSE).get(0).id();
    }

    @Test
    void createPersistsTransactionWithCategoryName() {
        UUID userId = testAuth.createUser().id();
        UUID categoryId = expenseCategory(userId);

        TransactionResponse created = service.create(userId, new CreateTransactionRequest(
                categoryId, CategoryType.EXPENSE, new BigDecimal("1500.00"),
                "Обед", LocalDate.now()));

        assertThat(created.id()).isNotNull();
        assertThat(created.amount()).isEqualByComparingTo("1500.00");
        assertThat(created.categoryName()).isNotBlank();
    }

    @Test
    void createRejectsTypeMismatchWithCategory() {
        UUID userId = testAuth.createUser().id();
        UUID expenseId = expenseCategory(userId);
        // тип операции INCOME, а категория EXPENSE
        assertThatThrownBy(() -> service.create(userId, new CreateTransactionRequest(
                expenseId, CategoryType.INCOME, new BigDecimal("100.00"), null, LocalDate.now())))
                .isInstanceOf(DomainException.class);
    }

    @Test
    void createRejectsCategoryOfAnotherUser() {
        UUID owner = testAuth.createUser().id();
        UUID other = testAuth.createUser().id();
        CategoryResponse ownCat = categoryService.create(owner,
                new CreateCategoryRequest("Личное", CategoryType.EXPENSE, null, null));
        assertThatThrownBy(() -> service.create(other, new CreateTransactionRequest(
                ownCat.id(), CategoryType.EXPENSE, new BigDecimal("100.00"), null, LocalDate.now())))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void listIsScopedToUserAndFiltersByType() {
        UUID userId = testAuth.createUser().id();
        UUID other = testAuth.createUser().id();
        UUID expenseId = expenseCategory(userId);
        UUID incomeId = categoryService.list(userId, CategoryType.INCOME).get(0).id();

        service.create(userId, new CreateTransactionRequest(
                expenseId, CategoryType.EXPENSE, new BigDecimal("100.00"), null, LocalDate.now()));
        service.create(userId, new CreateTransactionRequest(
                incomeId, CategoryType.INCOME, new BigDecimal("500.00"), null, LocalDate.now()));

        PageResponse<TransactionResponse> expenses =
                service.list(userId, null, null, CategoryType.EXPENSE, null, 0, 20);
        assertThat(expenses.items()).hasSize(1);
        assertThat(expenses.items().get(0).type()).isEqualTo("EXPENSE");

        PageResponse<TransactionResponse> otherUser =
                service.list(other, null, null, null, null, 0, 20);
        assertThat(otherUser.items()).isEmpty();
    }

    @Test
    void updateChangesAmountAndCategory() {
        UUID userId = testAuth.createUser().id();
        UUID expenseId = expenseCategory(userId);
        TransactionResponse created = service.create(userId, new CreateTransactionRequest(
                expenseId, CategoryType.EXPENSE, new BigDecimal("100.00"), null, LocalDate.now()));

        TransactionResponse updated = service.update(userId, created.id(),
                new com.aifb.platform.finance.transaction.api.dto.UpdateTransactionRequest(
                        expenseId, CategoryType.EXPENSE, new BigDecimal("250.50"),
                        "правка", LocalDate.now()));
        assertThat(updated.amount()).isEqualByComparingTo("250.50");
        assertThat(updated.note()).isEqualTo("правка");
    }

    @Test
    void deleteRemovesTransaction() {
        UUID userId = testAuth.createUser().id();
        UUID expenseId = expenseCategory(userId);
        TransactionResponse created = service.create(userId, new CreateTransactionRequest(
                expenseId, CategoryType.EXPENSE, new BigDecimal("100.00"), null, LocalDate.now()));
        service.delete(userId, created.id());
        assertThat(service.list(userId, null, null, null, null, 0, 20).items()).isEmpty();
    }

    @Test
    void getOtherUsersTransactionNotFound() {
        UUID owner = testAuth.createUser().id();
        UUID other = testAuth.createUser().id();
        UUID expenseId = expenseCategory(owner);
        TransactionResponse created = service.create(owner, new CreateTransactionRequest(
                expenseId, CategoryType.EXPENSE, new BigDecimal("100.00"), null, LocalDate.now()));
        assertThatThrownBy(() -> service.get(other, created.id()))
                .isInstanceOf(NotFoundException.class);
    }
}
```

- [ ] **Step 4: Запустить тест — убедиться, что НЕ компилируется/падает**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test --tests 'com.aifb.platform.finance.transaction.TransactionServiceIT'
```
Expected: FAIL — `TransactionService` ещё не создан, компиляция падает.

- [ ] **Step 5: Создать `TransactionService`**

Create `.../finance/transaction/service/TransactionService.java`:

```java
package com.aifb.platform.finance.transaction.service;

import com.aifb.platform.common.api.PageResponse;
import com.aifb.platform.common.exception.ErrorCode;
import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.repository.CategoryRepository;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
import com.aifb.platform.finance.transaction.api.dto.TransactionResponse;
import com.aifb.platform.finance.transaction.api.dto.UpdateTransactionRequest;
import com.aifb.platform.finance.transaction.domain.Transaction;
import com.aifb.platform.finance.transaction.repository.TransactionRepository;
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

    public TransactionService(TransactionRepository repository,
                              CategoryRepository categoryRepository) {
        this.repository = repository;
        this.categoryRepository = categoryRepository;
    }

    @Transactional(readOnly = true)
    public PageResponse<TransactionResponse> list(UUID userId, LocalDate from, LocalDate to,
                                                  CategoryType type, UUID categoryId,
                                                  int page, int size) {
        Pageable pageable = PageRequest.of(page, size,
                Sort.by(Sort.Direction.DESC, "occurredOn")
                        .and(Sort.by(Sort.Direction.DESC, "createdAt")));
        Page<Transaction> result = repository.search(userId, from, to, type, categoryId, pageable);

        Map<UUID, Category> categories = categoryRepository.findByIdInAndDeletedAtIsNull(
                        result.getContent().stream().map(Transaction::getCategoryId).distinct().toList())
                .stream().collect(Collectors.toMap(Category::getId, Function.identity()));

        Page<TransactionResponse> mapped = result.map(
                t -> TransactionResponse.from(t, categories.get(t.getCategoryId())));
        return PageResponse.from(mapped);
    }

    @Transactional(readOnly = true)
    public TransactionResponse get(UUID userId, UUID id) {
        Transaction t = repository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new NotFoundException("Транзакция не найдена"));
        return TransactionResponse.from(t, loadCategory(t.getCategoryId()));
    }

    @Transactional
    public TransactionResponse create(UUID userId, CreateTransactionRequest req) {
        Category category = resolveCategory(userId, req.categoryId(), req.type());
        Transaction t = new Transaction(userId, category.getId(), req.type(),
                req.amount(), req.note(), req.occurredOn());
        return TransactionResponse.from(repository.save(t), category);
    }

    @Transactional
    public TransactionResponse update(UUID userId, UUID id, UpdateTransactionRequest req) {
        Transaction t = repository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new NotFoundException("Транзакция не найдена"));
        Category category = resolveCategory(userId, req.categoryId(), req.type());
        t.setCategoryId(category.getId());
        t.setType(req.type());
        t.setAmount(req.amount());
        t.setNote(req.note());
        t.setOccurredOn(req.occurredOn());
        return TransactionResponse.from(repository.save(t), category);
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        Transaction t = repository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new NotFoundException("Транзакция не найдена"));
        repository.delete(t);
    }

    /** Категория должна быть видима пользователю и иметь тот же тип, что и операция. */
    private Category resolveCategory(UUID userId, UUID categoryId, CategoryType type) {
        Category category = categoryRepository.findVisibleByIdForUser(categoryId, userId)
                .orElseThrow(() -> new NotFoundException("Категория не найдена"));
        if (category.getType() != type) {
            throw new DomainException(ErrorCode.VALIDATION_FAILED,
                    "Тип операции не совпадает с типом категории");
        }
        return category;
    }

    private Category loadCategory(UUID categoryId) {
        List<Category> found = categoryRepository.findByIdInAndDeletedAtIsNull(List.of(categoryId));
        return found.isEmpty() ? null : found.get(0);
    }
}
```

- [ ] **Step 6: Запустить тест — убедиться, что проходит**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test --tests 'com.aifb.platform.finance.transaction.TransactionServiceIT'
```
Expected: `BUILD SUCCESSFUL`, 7 тестов passed.

- [ ] **Step 7: Commit**

```bash
git add backend/src/main/java/com/aifb/platform/finance/transaction/api backend/src/main/java/com/aifb/platform/finance/transaction/service backend/src/test/java/com/aifb/platform/finance/transaction/TransactionServiceIT.java
git commit -m "feat(transaction): сервис транзакций с тестами (валидация типа, изоляция, фильтры)"
```

---

## Task 7: Транзакция — контроллер и web-тесты

**Files:**
- Create: `.../finance/transaction/api/TransactionController.java`
- Test: `backend/src/test/java/com/aifb/platform/finance/transaction/TransactionApiIT.java`

- [ ] **Step 1: Написать падающий web-тест**

Create `backend/src/test/java/com/aifb/platform/finance/transaction/TransactionApiIT.java`:

```java
package com.aifb.platform.finance.transaction;

import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;

import java.time.LocalDate;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class TransactionApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired CategoryService categoryService;

    @Test
    void createAndListTransaction() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        UUID categoryId = categoryService.list(user.id(), CategoryType.EXPENSE).get(0).id();

        mockMvc.perform(post("/api/v1/transactions")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"categoryId":"%s","type":"EXPENSE","amount":1200.50,
                                 "note":"Продукты","occurredOn":"%s"}
                                """.formatted(categoryId, LocalDate.now())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.amount").value(1200.50))
                .andExpect(jsonPath("$.data.categoryName").isNotEmpty());

        mockMvc.perform(get("/api/v1/transactions")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items.length()").value(1))
                .andExpect(jsonPath("$.data.total").value(1));
    }

    @Test
    void createRejectsTypeMismatch() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        UUID expenseId = categoryService.list(user.id(), CategoryType.EXPENSE).get(0).id();
        mockMvc.perform(post("/api/v1/transactions")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"categoryId":"%s","type":"INCOME","amount":100.00,"occurredOn":"%s"}
                                """.formatted(expenseId, LocalDate.now())))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("VALIDATION_FAILED"));
    }

    @Test
    void listRequiresAuth() throws Exception {
        mockMvc.perform(get("/api/v1/transactions"))
                .andExpect(status().isUnauthorized());
    }
}
```

- [ ] **Step 2: Запустить тест — убедиться, что падает**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test --tests 'com.aifb.platform.finance.transaction.TransactionApiIT'
```
Expected: FAIL — контроллера нет, эндпоинт `/api/v1/transactions` недоступен.

- [ ] **Step 3: Создать `TransactionController`**

Create `.../finance/transaction/api/TransactionController.java`:

```java
package com.aifb.platform.finance.transaction.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.api.PageResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
import com.aifb.platform.finance.transaction.api.dto.TransactionResponse;
import com.aifb.platform.finance.transaction.api.dto.UpdateTransactionRequest;
import com.aifb.platform.finance.transaction.service.TransactionService;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/transactions")
public class TransactionController {

    private final TransactionService service;

    public TransactionController(TransactionService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<PageResponse<TransactionResponse>> list(
            @CurrentUser AuthPrincipal principal,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) CategoryType type,
            @RequestParam(required = false) UUID categoryId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.ok(service.list(principal.userId(), from, to, type, categoryId, page, size));
    }

    @GetMapping("/{id}")
    public ApiResponse<TransactionResponse> get(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id) {
        return ApiResponse.ok(service.get(principal.userId(), id));
    }

    @PostMapping
    public ApiResponse<TransactionResponse> create(
            @CurrentUser AuthPrincipal principal,
            @Valid @RequestBody CreateTransactionRequest request) {
        return ApiResponse.ok(service.create(principal.userId(), request));
    }

    @PutMapping("/{id}")
    public ApiResponse<TransactionResponse> update(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id,
            @Valid @RequestBody UpdateTransactionRequest request) {
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

- [ ] **Step 4: Запустить тест — убедиться, что проходит**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test --tests 'com.aifb.platform.finance.transaction.TransactionApiIT'
```
Expected: `BUILD SUCCESSFUL`, 3 теста passed.

- [ ] **Step 5: Прогнать весь тестовый набор**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew test
```
Expected: `BUILD SUCCESSFUL`, все тесты (Smoke + Category*IT + Transaction*IT) passed.

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/com/aifb/platform/finance/transaction/api/TransactionController.java backend/src/test/java/com/aifb/platform/finance/transaction/TransactionApiIT.java
git commit -m "feat(transaction): REST-контроллер транзакций с web-тестами"
```

---

## Финальная проверка (ручной прогон через API)

- [ ] **Step 1: Запустить БД и бэк**

```bash
docker start aifb-db 2>/dev/null || docker run -d --name aifb-db \
  -e POSTGRES_DB=aifb -e POSTGRES_USER=aifb -e POSTGRES_PASSWORD=aifb -p 5432:5432 postgres:16
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home \
  ./gradlew bootRun
```

- [ ] **Step 2: Проверить категории и создание транзакции через curl**

```bash
TOKEN=$(curl -s -X POST http://localhost:9090/api/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"t2@example.com","password":"Passw0rd!23","fullName":"T2"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"]["tokens"]["accessToken"])')

# список категорий расходов
curl -s "http://localhost:9090/api/v1/categories?type=EXPENSE" -H "Authorization: Bearer $TOKEN"
```
Expected: JSON со списком системных категорий (Еда, Транспорт, …).

---

## Self-review (выполнено при написании плана)

- **Покрытие спеки:** таблицы `categories`/`transactions`, гибридные категории + сидинг, мягкое удаление, CRUD категорий/транзакций, валидация совпадения типа, фильтрация/пагинация списка, изоляция по `user_id` — все из секций спеки «Модель данных», «REST API → Категории/Транзакции» реализованы. Статистика и цели — в Планах 2/3 (вне этого плана).
- **Плейсхолдеры:** отсутствуют — каждый шаг содержит полный код или точную команду с ожидаемым результатом.
- **Согласованность типов:** `CategoryType` объявлен один раз (Task 2) и используется в `Category`, `Transaction`, DTO, репозиториях и сервисах единообразно. Сигнатуры `service.list(...)`, `service.create(...)`, `findVisibleByIdForUser(...)`, `findByIdInAndDeletedAtIsNull(...)` совпадают между объявлением и вызовами в тестах.
- **Примечание по валюте:** в соответствии со спекой колонка валюты в таблицах не заводится; символ валюты подставляется на фронте (План 3).
