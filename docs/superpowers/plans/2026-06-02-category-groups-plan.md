# План — Группы (папки) категорий

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Добавить группы (папки) категорий: пользовательские, типизированные (INCOME/EXPENSE), scope-aware (личные/семейные), с CRUD и привязкой категорий через `group_id` (авто-разгруппировка при удалении группы).

**Architecture:** Новый модуль `finance/group` по образцу `finance/category`. Сущность `CategoryGroup` (без `is_system`) с дискриминатором `household_id` (личное/семейное). Категория получает `group_id` (FK `ON DELETE SET NULL`). Права на семейные группы — через существующий `HouseholdContextService` (OWNER/ADULT). `CategoryType` (INCOME/EXPENSE) переиспользуется.

**Tech Stack:** Spring Boot 3.3.5, Java 21, Spring Data JPA, PostgreSQL, Flyway; Flutter 3.44 (Riverpod/Dio); тесты — Testcontainers + MockMvc + mocktail.

**Предусловие:** ветка `feature/category-groups` (от `feature/family-budget`). Семейный бюджет (V8–V9, `HouseholdContextService`, scope в категориях) реализован.

---

## Структура файлов

**Backend создаваемые:**
- `backend/src/main/resources/db/migration/V10__category_groups.sql`
- `finance/group/domain/CategoryGroup.java`
- `finance/group/repository/CategoryGroupRepository.java`
- `finance/group/service/CategoryGroupService.java`
- `finance/group/api/CategoryGroupController.java`
- `finance/group/api/dto/{GroupResponse,CreateGroupRequest,UpdateGroupRequest}.java`

**Backend изменяемые:**
- `finance/category/domain/Category.java` (+ `groupId`)
- `finance/category/api/dto/{CreateCategoryRequest,UpdateCategoryRequest,CategoryResponse}.java` (+ `groupId`)
- `finance/category/service/CategoryService.java` (валидация группы)

**Frontend создаваемые:** `features/groups/data/models/group_model.dart`, `.../data/groups_data_source.dart`, `.../data/groups_repository.dart`, `.../presentation/providers/groups_providers.dart`, `.../presentation/pages/groups_page.dart`, `test/features/groups/groups_repository_test.dart`; route в `routes.dart`/`app_router.dart`; `+groupId` в `CategoryModel`.

**Тесты backend:** `finance/group/CategoryGroupServiceIT.java`, `CategoryGroupApiIT.java`, `finance/category/CategoryGroupLinkIT.java`.

Команды backend — из `backend/`, `JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home`; Docker запущен. Frontend — из `frontend/`.

---

## Task 1: Миграция V10, сущность CategoryGroup, репозиторий, group_id в Category

**Files:** V10 sql; `CategoryGroup.java`; `CategoryGroupRepository.java`; modify `Category.java`.

- [ ] **Step 1: Миграция** `backend/src/main/resources/db/migration/V10__category_groups.sql`:
```sql
CREATE TABLE category_groups (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    household_id UUID REFERENCES households(id) ON DELETE CASCADE,
    name VARCHAR(80) NOT NULL,
    type VARCHAR(10) NOT NULL,
    icon VARCHAR(40),
    color VARCHAR(9),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT chk_category_groups_type CHECK (type IN ('INCOME', 'EXPENSE'))
);

CREATE INDEX idx_category_groups_user ON category_groups (user_id) WHERE household_id IS NULL;
CREATE INDEX idx_category_groups_household ON category_groups (household_id) WHERE household_id IS NOT NULL;

ALTER TABLE categories ADD COLUMN group_id UUID REFERENCES category_groups(id) ON DELETE SET NULL;
```

- [ ] **Step 2: Сущность** `finance/group/domain/CategoryGroup.java`:
```java
package com.aifb.platform.finance.group.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import com.aifb.platform.finance.category.domain.CategoryType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "category_groups")
public class CategoryGroup extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "household_id")
    private UUID householdId;

    @Column(nullable = false, length = 80)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private CategoryType type;

    @Column(length = 40)
    private String icon;

    @Column(length = 9)
    private String color;

    protected CategoryGroup() {
    }

    public CategoryGroup(UUID userId, String name, CategoryType type, String icon, String color) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.name = name;
        this.type = type;
        this.icon = icon;
        this.color = color;
    }

    public UUID getUserId() { return userId; }
    public UUID getHouseholdId() { return householdId; }
    public boolean isShared() { return householdId != null; }
    public String getName() { return name; }
    public CategoryType getType() { return type; }
    public String getIcon() { return icon; }
    public String getColor() { return color; }

    public void assignHousehold(UUID householdId) { this.householdId = householdId; }
    public void setName(String name) { this.name = name; }
    public void setIcon(String icon) { this.icon = icon; }
    public void setColor(String color) { this.color = color; }
}
```

- [ ] **Step 3: Репозиторий** `finance/group/repository/CategoryGroupRepository.java`:
```java
package com.aifb.platform.finance.group.repository;

import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.group.domain.CategoryGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CategoryGroupRepository extends JpaRepository<CategoryGroup, UUID> {

    @Query("""
            select g from CategoryGroup g
            where g.userId = :userId and g.householdId is null
              and (:type is null or g.type = :type)
            order by g.name asc
            """)
    List<CategoryGroup> findVisiblePersonal(@Param("userId") UUID userId,
                                            @Param("type") CategoryType type);

    @Query("""
            select g from CategoryGroup g
            where g.householdId = :householdId
              and (:type is null or g.type = :type)
            order by g.name asc
            """)
    List<CategoryGroup> findVisibleFamily(@Param("householdId") UUID householdId,
                                          @Param("type") CategoryType type);

    Optional<CategoryGroup> findByIdAndUserIdAndHouseholdIdIsNull(UUID id, UUID userId);

    Optional<CategoryGroup> findByIdAndHouseholdId(UUID id, UUID householdId);
}
```

- [ ] **Step 4: Добавить `group_id` в `Category`** — in `finance/category/domain/Category.java` add field (after `householdId`):
```java
    @Column(name = "group_id")
    private UUID groupId;
```
and methods (with the other getters):
```java
    public UUID getGroupId() { return groupId; }
    public void assignGroup(UUID groupId) { this.groupId = groupId; }
```

- [ ] **Step 5: Проверить схему**
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.SmokeContextIT'
```
Expected: BUILD SUCCESSFUL (V10 применена, validate подтверждает `CategoryGroup` + `categories.group_id`).

- [ ] **Step 6: Commit**
```bash
git add backend/src/main/resources/db/migration/V10__category_groups.sql backend/src/main/java/com/aifb/platform/finance/group/domain backend/src/main/java/com/aifb/platform/finance/group/repository backend/src/main/java/com/aifb/platform/finance/category/domain/Category.java
git commit -m "feat(group): миграция V10, сущность CategoryGroup, репозиторий, group_id в Category"
```

---

## Task 2: Группы — DTO, сервис, тесты

**Files:** group dto x3; `CategoryGroupService.java`; test `CategoryGroupServiceIT.java`.

- [ ] **Step 1: DTO**

`finance/group/api/dto/GroupResponse.java`:
```java
package com.aifb.platform.finance.group.api.dto;

import com.aifb.platform.finance.group.domain.CategoryGroup;

import java.util.UUID;

public record GroupResponse(
        UUID id, String name, String type, String icon, String color, boolean shared) {

    public static GroupResponse from(CategoryGroup g) {
        return new GroupResponse(g.getId(), g.getName(), g.getType().name(),
                g.getIcon(), g.getColor(), g.isShared());
    }
}
```
`finance/group/api/dto/CreateGroupRequest.java`:
```java
package com.aifb.platform.finance.group.api.dto;

import com.aifb.platform.finance.category.domain.CategoryType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CreateGroupRequest(
        @NotBlank @Size(max = 80) String name,
        @NotNull CategoryType type,
        @Size(max = 40) String icon,
        @Size(max = 9) String color,
        boolean shared) {
}
```
`finance/group/api/dto/UpdateGroupRequest.java`:
```java
package com.aifb.platform.finance.group.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateGroupRequest(
        @NotBlank @Size(max = 80) String name,
        @Size(max = 40) String icon,
        @Size(max = 9) String color) {
}
```

- [ ] **Step 2: Падающий тест** `backend/src/test/java/com/aifb/platform/finance/group/CategoryGroupServiceIT.java`:
```java
package com.aifb.platform.finance.group;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.group.api.dto.CreateGroupRequest;
import com.aifb.platform.finance.group.api.dto.GroupResponse;
import com.aifb.platform.finance.group.api.dto.UpdateGroupRequest;
import com.aifb.platform.finance.group.service.CategoryGroupService;
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

class CategoryGroupServiceIT extends AbstractIntegrationTest {

    @Autowired CategoryGroupService service;
    @Autowired HouseholdService householdService;
    @Autowired TestAuth testAuth;

    @Test
    void createPersonalGroupVisibleOnlyToOwnerScope() {
        UUID userId = testAuth.createUser().id();
        GroupResponse g = service.create(userId,
                new CreateGroupRequest("Коммунальные", CategoryType.EXPENSE, "home", "#888888", false));
        assertThat(g.shared()).isFalse();
        assertThat(service.list(userId, CategoryType.EXPENSE, Scope.PERSONAL))
                .anyMatch(x -> x.id().equals(g.id()));
        assertThat(service.list(userId, CategoryType.EXPENSE, Scope.FAMILY)).isEmpty();
    }

    @Test
    void sharedGroupVisibleToFamily() {
        UUID owner = testAuth.createUser().id();
        UUID member = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(member, new JoinHouseholdRequest(code));
        GroupResponse g = service.create(owner,
                new CreateGroupRequest("Коммунальные", CategoryType.EXPENSE, null, null, true));
        assertThat(g.shared()).isTrue();
        assertThat(service.list(member, CategoryType.EXPENSE, Scope.FAMILY))
                .anyMatch(x -> x.id().equals(g.id()));
    }

    @Test
    void childCannotCreateSharedGroup() {
        UUID owner = testAuth.createUser().id();
        UUID child = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(child, new JoinHouseholdRequest(code));
        householdService.changeRole(owner, child, HouseholdRole.CHILD);
        assertThatThrownBy(() -> service.create(child,
                new CreateGroupRequest("X", CategoryType.EXPENSE, null, null, true)))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void sharedCreateWithoutHouseholdConflicts() {
        UUID solo = testAuth.createUser().id();
        assertThatThrownBy(() -> service.create(solo,
                new CreateGroupRequest("X", CategoryType.EXPENSE, null, null, true)))
                .isInstanceOf(com.aifb.platform.common.exception.ConflictException.class);
    }

    @Test
    void updateAndDeletePersonalGroup() {
        UUID userId = testAuth.createUser().id();
        GroupResponse g = service.create(userId,
                new CreateGroupRequest("Старое", CategoryType.EXPENSE, null, null, false));
        GroupResponse upd = service.update(userId, g.id(),
                new UpdateGroupRequest("Новое", "tag", "#111111"));
        assertThat(upd.name()).isEqualTo("Новое");
        service.delete(userId, g.id());
        assertThat(service.list(userId, CategoryType.EXPENSE, Scope.PERSONAL))
                .noneMatch(x -> x.id().equals(g.id()));
    }

    @Test
    void updateOthersGroupNotFound() {
        UUID owner = testAuth.createUser().id();
        UUID other = testAuth.createUser().id();
        GroupResponse g = service.create(owner,
                new CreateGroupRequest("Моя", CategoryType.EXPENSE, null, null, false));
        assertThatThrownBy(() -> service.update(other, g.id(),
                new UpdateGroupRequest("X", null, null)))
                .isInstanceOf(NotFoundException.class);
    }
}
```
Run `... --tests 'com.aifb.platform.finance.group.CategoryGroupServiceIT'` → FAIL.

- [ ] **Step 3: Сервис** `finance/group/service/CategoryGroupService.java`:
```java
package com.aifb.platform.finance.group.service;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.group.api.dto.CreateGroupRequest;
import com.aifb.platform.finance.group.api.dto.GroupResponse;
import com.aifb.platform.finance.group.api.dto.UpdateGroupRequest;
import com.aifb.platform.finance.group.domain.CategoryGroup;
import com.aifb.platform.finance.group.repository.CategoryGroupRepository;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class CategoryGroupService {

    private final CategoryGroupRepository repository;
    private final HouseholdContextService householdContext;

    public CategoryGroupService(CategoryGroupRepository repository,
                                HouseholdContextService householdContext) {
        this.repository = repository;
        this.householdContext = householdContext;
    }

    @Transactional(readOnly = true)
    public List<GroupResponse> list(UUID userId, CategoryType type, Scope scope) {
        List<CategoryGroup> groups;
        if (scope == Scope.FAMILY) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            groups = ctx == null ? List.of()
                    : repository.findVisibleFamily(ctx.householdId(), type);
        } else {
            groups = repository.findVisiblePersonal(userId, type);
        }
        return groups.stream().map(GroupResponse::from).toList();
    }

    @Transactional
    public GroupResponse create(UUID userId, CreateGroupRequest req) {
        CategoryGroup group = new CategoryGroup(userId, req.name(), req.type(), req.icon(), req.color());
        if (req.shared()) {
            HouseholdContext ctx = householdContext.requireManageSharedContent(userId);
            group.assignHousehold(ctx.householdId());
        }
        return GroupResponse.from(repository.save(group));
    }

    @Transactional
    public GroupResponse update(UUID userId, UUID id, UpdateGroupRequest req) {
        CategoryGroup group = manageableGroup(userId, id);
        group.setName(req.name());
        group.setIcon(req.icon());
        group.setColor(req.color());
        return GroupResponse.from(repository.save(group));
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        CategoryGroup group = manageableGroup(userId, id);
        repository.delete(group); // категории разгруппируются через FK ON DELETE SET NULL
    }

    private CategoryGroup manageableGroup(UUID userId, UUID id) {
        CategoryGroup group = repository.findById(id)
                .orElseThrow(() -> new NotFoundException("Группа не найдена"));
        if (group.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null || !ctx.householdId().equals(group.getHouseholdId())) {
                throw new NotFoundException("Группа не найдена");
            }
            if (!ctx.canManageSharedContent()) {
                throw new ForbiddenException("Недостаточно прав для семейной группы");
            }
            return group;
        }
        if (!userId.equals(group.getUserId())) {
            throw new NotFoundException("Группа не найдена");
        }
        return group;
    }
}
```

- [ ] **Step 4: Run** `... --tests 'com.aifb.platform.finance.group.CategoryGroupServiceIT'` → BUILD SUCCESSFUL, 6 tests.

- [ ] **Step 5: Commit**
```bash
git add backend/src/main/java/com/aifb/platform/finance/group/api/dto backend/src/main/java/com/aifb/platform/finance/group/service backend/src/test/java/com/aifb/platform/finance/group/CategoryGroupServiceIT.java
git commit -m "feat(group): сервис групп категорий с тестами (scope, права OWNER/ADULT)"
```

---

## Task 3: Группы — контроллер и web-тесты

**Files:** `CategoryGroupController.java`; test `CategoryGroupApiIT.java`.

- [ ] **Step 1: Падающий web-тест** `backend/src/test/java/com/aifb/platform/finance/group/CategoryGroupApiIT.java`:
```java
package com.aifb.platform.finance.group;

import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class CategoryGroupApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;

    @Test
    void listRequiresAuth() throws Exception {
        mockMvc.perform(get("/api/v1/groups").param("type", "EXPENSE"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void createAndListGroup() throws Exception {
        String bearer = testAuth.createUser().bearer();
        mockMvc.perform(post("/api/v1/groups")
                        .header(HttpHeaders.AUTHORIZATION, bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Коммунальные\",\"type\":\"EXPENSE\",\"icon\":\"home\",\"color\":\"#888888\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Коммунальные"))
                .andExpect(jsonPath("$.data.shared").value(false));

        mockMvc.perform(get("/api/v1/groups").param("type", "EXPENSE").param("scope", "PERSONAL")
                        .header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].name").value("Коммунальные"));
    }

    @Test
    void createRejectsBlankName() throws Exception {
        String bearer = testAuth.createUser().bearer();
        mockMvc.perform(post("/api/v1/groups")
                        .header(HttpHeaders.AUTHORIZATION, bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"\",\"type\":\"EXPENSE\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("VALIDATION_FAILED"));
    }
}
```
Run → FAIL (no controller).

- [ ] **Step 2: Контроллер** `finance/group/api/CategoryGroupController.java`:
```java
package com.aifb.platform.finance.group.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.group.api.dto.CreateGroupRequest;
import com.aifb.platform.finance.group.api.dto.GroupResponse;
import com.aifb.platform.finance.group.api.dto.UpdateGroupRequest;
import com.aifb.platform.finance.group.service.CategoryGroupService;
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
@RequestMapping("/api/v1/groups")
public class CategoryGroupController {

    private final CategoryGroupService service;

    public CategoryGroupController(CategoryGroupService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<List<GroupResponse>> list(
            @CurrentUser AuthPrincipal principal,
            @RequestParam(required = false) CategoryType type,
            @RequestParam(defaultValue = "PERSONAL") Scope scope) {
        return ApiResponse.ok(service.list(principal.userId(), type, scope));
    }

    @PostMapping
    public ApiResponse<GroupResponse> create(
            @CurrentUser AuthPrincipal principal,
            @Valid @RequestBody CreateGroupRequest request) {
        return ApiResponse.ok(service.create(principal.userId(), request));
    }

    @PutMapping("/{id}")
    public ApiResponse<GroupResponse> update(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id,
            @Valid @RequestBody UpdateGroupRequest request) {
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
(SecurityConfig не трогаем — `.anyRequest().authenticated()` уже закрывает.)

- [ ] **Step 3: Run** `... --tests 'com.aifb.platform.finance.group.CategoryGroupApiIT'` → BUILD SUCCESSFUL, 3 tests.

- [ ] **Step 4: Commit**
```bash
git add backend/src/main/java/com/aifb/platform/finance/group/api/CategoryGroupController.java backend/src/test/java/com/aifb/platform/finance/group/CategoryGroupApiIT.java
git commit -m "feat(group): REST-контроллер групп с web-тестами"
```

---

## Task 4: Привязка категории к группе (groupId)

**Files:** modify category DTOs + `CategoryService.java`; test `finance/category/CategoryGroupLinkIT.java`.

- [ ] **Step 1: DTO категорий.**
`CreateCategoryRequest.java` — append `UUID groupId` component (nullable, no validation annotation):
```java
package com.aifb.platform.finance.category.api.dto;

import com.aifb.platform.finance.category.domain.CategoryType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record CreateCategoryRequest(
        @NotBlank @Size(max = 80) String name,
        @NotNull CategoryType type,
        @Size(max = 40) String icon,
        @Size(max = 9) String color,
        boolean shared,
        UUID groupId) {
}
```
`UpdateCategoryRequest.java` — append `UUID groupId`:
```java
package com.aifb.platform.finance.category.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record UpdateCategoryRequest(
        @NotBlank @Size(max = 80) String name,
        @Size(max = 40) String icon,
        @Size(max = 9) String color,
        UUID groupId) {
}
```
`CategoryResponse.java` — add `UUID groupId`:
```java
package com.aifb.platform.finance.category.api.dto;

import com.aifb.platform.finance.category.domain.Category;

import java.util.UUID;

public record CategoryResponse(
        UUID id, String name, String type, String icon, String color,
        boolean system, boolean shared, UUID groupId) {

    public static CategoryResponse from(Category c) {
        return new CategoryResponse(
                c.getId(), c.getName(), c.getType().name(),
                c.getIcon(), c.getColor(), c.isSystem(), c.isShared(), c.getGroupId());
    }
}
```

- [ ] **Step 2: Падающий тест** `backend/src/test/java/com/aifb/platform/finance/category/CategoryGroupLinkIT.java`:
```java
package com.aifb.platform.finance.category;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.finance.category.api.dto.CategoryResponse;
import com.aifb.platform.finance.category.api.dto.CreateCategoryRequest;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.finance.group.api.dto.CreateGroupRequest;
import com.aifb.platform.finance.group.api.dto.GroupResponse;
import com.aifb.platform.finance.group.service.CategoryGroupService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CategoryGroupLinkIT extends AbstractIntegrationTest {

    @Autowired CategoryService categoryService;
    @Autowired CategoryGroupService groupService;
    @Autowired TestAuth testAuth;

    @Test
    void categoryWithMatchingGroupIsLinked() {
        UUID userId = testAuth.createUser().id();
        GroupResponse group = groupService.create(userId,
                new CreateGroupRequest("Коммунальные", CategoryType.EXPENSE, null, null, false));
        CategoryResponse cat = categoryService.create(userId,
                new CreateCategoryRequest("Свет", CategoryType.EXPENSE, null, null, false, group.id()));
        assertThat(cat.groupId()).isEqualTo(group.id());
    }

    @Test
    void groupTypeMismatchRejected() {
        UUID userId = testAuth.createUser().id();
        GroupResponse incomeGroup = groupService.create(userId,
                new CreateGroupRequest("Доходы", CategoryType.INCOME, null, null, false));
        assertThatThrownBy(() -> categoryService.create(userId,
                new CreateCategoryRequest("Свет", CategoryType.EXPENSE, null, null, false, incomeGroup.id())))
                .isInstanceOf(DomainException.class);
    }

    @Test
    void othersGroupRejected() {
        UUID owner = testAuth.createUser().id();
        UUID other = testAuth.createUser().id();
        GroupResponse group = groupService.create(owner,
                new CreateGroupRequest("Чужая", CategoryType.EXPENSE, null, null, false));
        assertThatThrownBy(() -> categoryService.create(other,
                new CreateCategoryRequest("Свет", CategoryType.EXPENSE, null, null, false, group.id())))
                .isInstanceOf(DomainException.class);
    }

    @Test
    void deletingGroupUngroupsCategory() {
        UUID userId = testAuth.createUser().id();
        GroupResponse group = groupService.create(userId,
                new CreateGroupRequest("Коммунальные", CategoryType.EXPENSE, null, null, false));
        CategoryResponse cat = categoryService.create(userId,
                new CreateCategoryRequest("Свет", CategoryType.EXPENSE, null, null, false, group.id()));
        groupService.delete(userId, group.id());
        // после удаления группы категория видна и без группы
        assertThat(categoryService.list(userId, CategoryType.EXPENSE, Scope.PERSONAL))
                .filteredOn(c -> c.id().equals(cat.id()))
                .singleElement()
                .satisfies(c -> assertThat(c.groupId()).isNull());
    }
}
```
Run → FAIL (constructor arity / validation not implemented).

- [ ] **Step 3: Обновить `CategoryService`.** Inject `CategoryGroupRepository groupRepository`. Add a helper and call it in `create`/`update`:
```java
    // imports to add:
    // import com.aifb.platform.common.exception.DomainException;
    // import com.aifb.platform.common.exception.ErrorCode;
    // import com.aifb.platform.finance.group.domain.CategoryGroup;
    // import com.aifb.platform.finance.group.repository.CategoryGroupRepository;
```
Constructor → add `CategoryGroupRepository groupRepository` param and assign field.

In `create`, after building the `Category` (both personal and shared branches) and BEFORE saving, resolve the group:
- personal branch: `applyGroup(category, req.groupId(), userId, null);`
- shared branch: `applyGroup(category, req.groupId(), userId, ctx.householdId());`
In `update`, after setting name/icon/color: `applyGroup(category, req.groupId(), userId, category.getHouseholdId());`

Add the helper:
```java
    private void applyGroup(Category category, UUID groupId, UUID userId, UUID householdId) {
        if (groupId == null) {
            category.assignGroup(null);
            return;
        }
        CategoryGroup group = groupRepository.findById(groupId)
                .orElseThrow(() -> new DomainException(ErrorCode.VALIDATION_FAILED, "Группа не найдена"));
        // scope группы должен совпадать со scope категории
        boolean sameScope = householdId == null
                ? (group.getHouseholdId() == null && userId.equals(group.getUserId()))
                : householdId.equals(group.getHouseholdId());
        if (!sameScope) {
            throw new DomainException(ErrorCode.VALIDATION_FAILED, "Группа недоступна в этом контексте");
        }
        if (group.getType() != category.getType()) {
            throw new DomainException(ErrorCode.VALIDATION_FAILED, "Тип группы не совпадает с категорией");
        }
        category.assignGroup(group.getId());
    }
```
(For shared category create, `category.assignHousehold(ctx.householdId())` is already called before `applyGroup`, so `category.getType()` is set and the scope check uses the passed `householdId`.)

- [ ] **Step 4: Run** `... --tests 'com.aifb.platform.finance.category.CategoryGroupLinkIT'` → BUILD SUCCESSFUL, 4 tests.

- [ ] **Step 5: Fix existing category tests for new constructor arity.**
`CategoryServiceIT.java`, `CategoryScopeIT.java`: every `new CreateCategoryRequest(name, type, icon, color, shared)` → append `, null` (no group). `CategoryApiIT.java` JSON bodies without `groupId` → null (ok). Run `... --tests 'com.aifb.platform.finance.category.*'` → all pass.

- [ ] **Step 6: Full backend suite + commit**
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test
git add backend/src/main/java/com/aifb/platform/finance/category backend/src/test/java/com/aifb/platform/finance/category
git commit -m "feat(group): привязка категории к группе (groupId) с валидацией типа и scope"
```
Report total backend test count.

---

## Task 5: Frontend — фича groups (экран + провайдеры + тест)

**Files:** group model/data source/repo/providers/page; CategoryModel groupId; routes.

- [ ] **Step 1: Endpoint + model.**
In `lib/core/network/api_endpoints.dart` add inside class: `static const String groups = '/groups';`
Create `lib/features/groups/data/models/group_model.dart`:
```dart
class GroupModel {
  const GroupModel({
    required this.id,
    required this.name,
    required this.type,
    required this.shared,
    this.icon,
    this.color,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        shared: json['shared'] as bool? ?? false,
        icon: json['icon'] as String?,
        color: json['color'] as String?,
      );

  final String id;
  final String name;
  final String type;
  final bool shared;
  final String? icon;
  final String? color;
}
```
Add `groupId` to `lib/features/transactions/data/models/category_model.dart`: add field `final String? groupId;`, constructor param `this.groupId`, and in `fromJson`: `groupId: json['groupId'] as String?`.

- [ ] **Step 2: Data source** `lib/features/groups/data/groups_data_source.dart`:
```dart
import 'package:aifb/core/network/api_endpoints.dart';
import 'package:aifb/core/network/envelope.dart';
import 'package:aifb/features/groups/data/models/group_model.dart';
import 'package:dio/dio.dart';

class GroupsDataSource {
  GroupsDataSource(this._dio);
  final Dio _dio;

  Future<List<GroupModel>> list(String? type, {String scope = 'PERSONAL'}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.groups,
      queryParameters: {if (type != null) 'type': type, 'scope': scope},
    );
    return unwrapList(res.data)
        .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GroupModel> create(Map<String, dynamic> body) async {
    final res =
        await _dio.post<Map<String, dynamic>>(ApiEndpoints.groups, data: body);
    return GroupModel.fromJson(unwrapObject(res.data));
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('${ApiEndpoints.groups}/$id');
  }
}
```

- [ ] **Step 3: Failing repo test** `test/features/groups/groups_repository_test.dart`:
```dart
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/groups/data/groups_data_source.dart';
import 'package:aifb/features/groups/data/groups_repository.dart';
import 'package:aifb/features/groups/data/models/group_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDs extends Mock implements GroupsDataSource {}

void main() {
  late _MockDs ds;
  late GroupsRepository repo;

  setUp(() {
    ds = _MockDs();
    repo = GroupsRepository(ds);
  });

  test('list returns Ok with groups', () async {
    when(() => ds.list('EXPENSE', scope: 'PERSONAL')).thenAnswer((_) async => const [
          GroupModel(id: 'g1', name: 'Коммунальные', type: 'EXPENSE', shared: false),
        ]);
    final result = await repo.list(type: 'EXPENSE');
    expect(result, isA<Ok<List<GroupModel>>>());
    expect((result as Ok<List<GroupModel>>).value.single.name, 'Коммунальные');
  });

  test('list maps error to Err', () async {
    when(() => ds.list(any(), scope: any(named: 'scope'))).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/groups')),
    );
    final result = await repo.list(type: 'EXPENSE');
    expect(result, isA<Err<List<GroupModel>>>());
  });
}
```
Run `cd frontend && flutter test test/features/groups/groups_repository_test.dart` → FAIL.

- [ ] **Step 4: Repository** `lib/features/groups/data/groups_repository.dart`:
```dart
import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/core/errors/error_mapper.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/groups/data/groups_data_source.dart';
import 'package:aifb/features/groups/data/models/group_model.dart';

class GroupsRepository {
  GroupsRepository(this._ds);
  final GroupsDataSource _ds;

  Future<Result<List<GroupModel>>> list({String? type, Scope scope = Scope.personal}) =>
      _guard(() => _ds.list(type, scope: scope.query));

  Future<Result<GroupModel>> create({
    required String name,
    required String type,
    bool shared = false,
    String? icon,
    String? color,
  }) =>
      _guard(() => _ds.create({
            'name': name,
            'type': type,
            'shared': shared,
            if (icon != null) 'icon': icon,
            if (color != null) 'color': color,
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

- [ ] **Step 5: Providers** `lib/features/groups/presentation/providers/groups_providers.dart`:
```dart
import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/core/network/dio_client.dart';
import 'package:aifb/features/groups/data/groups_data_source.dart';
import 'package:aifb/features/groups/data/groups_repository.dart';
import 'package:aifb/features/groups/data/models/group_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final groupsDataSourceProvider = Provider<GroupsDataSource>((ref) {
  return GroupsDataSource(ref.watch(dioProvider));
});

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return GroupsRepository(ref.watch(groupsDataSourceProvider));
});

final groupsProvider =
    FutureProvider.autoDispose.family<List<GroupModel>, Scope>((ref, scope) async {
  final result = await ref.watch(groupsRepositoryProvider).list(scope: scope);
  return switch (result) {
    Ok<List<GroupModel>>(value: final v) => v,
    Err<List<GroupModel>>(failure: final f) => throw Exception(f.toString()),
  };
});
```

- [ ] **Step 6: Экран** `lib/features/groups/presentation/pages/groups_page.dart`:
```dart
import 'package:aifb/core/domain/scope.dart';
import 'package:aifb/features/groups/presentation/providers/groups_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupsPage extends ConsumerWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(groupsProvider(Scope.personal));
    return Scaffold(
      appBar: AppBar(title: const Text('Группы')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Новая группа'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(groupsProvider(Scope.personal).future),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [const SizedBox(height: 80), Center(child: Text('Ошибка: $e'))],
          ),
          data: (groups) {
            if (groups.isEmpty) {
              return ListView(
                children: const [SizedBox(height: 120), Center(child: Text('Групп пока нет'))],
              );
            }
            return ListView.separated(
              itemCount: groups.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final g = groups[i];
                return ListTile(
                  title: Text(g.name),
                  subtitle: Text(g.type),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ref.read(groupsRepositoryProvider).delete(g.id);
                      ref.invalidate(groupsProvider(Scope.personal));
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
    final name = TextEditingController();
    var type = 'EXPENSE';
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Новая группа'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'EXPENSE', label: Text('Расход')),
                  ButtonSegment(value: 'INCOME', label: Text('Доход')),
                ],
                selected: {type},
                onSelectionChanged: (s) => setState(() => type = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                await ref.read(groupsRepositoryProvider)
                    .create(name: name.text.trim(), type: type);
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
    if ((created ?? false)) ref.invalidate(groupsProvider(Scope.personal));
  }
}
```

- [ ] **Step 7: Маршрут.** In `lib/app/router/routes.dart` App shell add `static const groups = _Route('groups', '/groups');`. In `lib/app/router/app_router.dart` add import (relative, matching file) `import '../../features/groups/presentation/pages/groups_page.dart';` and a GoRoute:
```dart
      GoRoute(
        path: AppRoutes.groups.path,
        name: AppRoutes.groups.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const GroupsPage(),
        ),
      ),
```

- [ ] **Step 8: Анализ + тесты + commit**
```bash
cd frontend && flutter analyze lib && flutter test
git add frontend/lib/core/network/api_endpoints.dart frontend/lib/features/groups frontend/lib/features/transactions/data/models/category_model.dart frontend/lib/app/router/routes.dart frontend/lib/app/router/app_router.dart frontend/test/features/groups
git commit -m "feat(frontend): фича groups — модель/data/провайдеры/экран + groupId в категории + маршрут"
```
Expected: analyze 0 errors/warnings (info-хинты ок); все тесты passed.

---

## Self-review (выполнено при написании плана)

- **Покрытие спеки:** `category_groups` (V10) + `categories.group_id` (FK SET NULL); модуль `finance/group` (CRUD, scope, права OWNER/ADULT через `HouseholdContextService`); привязка категории через `groupId` с валидацией типа и scope; фронт-фича `groups` (экран + `groupsProvider(scope)` + `CategoryModel.groupId`). Все секции спеки покрыты.
- **Плейсхолдеры:** нет — полный код либо точечные правки с указанием места; обновление существующих тестов под новую арность — конкретными заменами.
- **Согласованность типов:** `CategoryType` переиспользуется (без нового enum). `CategoryGroupService.list(userId,type,Scope)`/`create`/`update`/`delete`, `GroupResponse.from`, `applyGroup(...)` согласованы между объявлением и вызовами/тестами. `Scope` (PERSONAL/FAMILY) и `HouseholdContext.canManageSharedContent()` переиспользованы из семейного бюджета.
- **Намеренное упрощение vs спека:** в `CategoryResponse` добавлен только `groupId` (без `groupName`) — имя группы фронт берёт из `groupsProvider`; это убирает join/N+1 в списке категорий. Привязка категории к группе из UI — вне объёма (нет экрана редактирования категории), backend-поддержка `groupId` реализована полностью.
