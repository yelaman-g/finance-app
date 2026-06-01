# План 1 — Backend: Семья и участники

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Реализовать сущность семьи (household), членство и роли (OWNER/ADULT/CHILD): создание семьи, вступление по коду, смену ролей, удаление участника, выход и роспуск — с интеграционными тестами.

**Architecture:** Новый модуль `platform/household` по образцу `auth`/`finance`. Одна семья на пользователя: на `users` добавляются `household_id` и `household_role`. Сущность `Household` хранит владельца и код-приглашение. Права проверяются в сервисе по `household_role` загруженного `User` (JWT/`AuthPrincipal` не меняем — `userId` берём из `@CurrentUser`, `User` грузим из БД). Финансовые таблицы в этом плане не трогаем (их scope — План 2).

**Tech Stack:** Spring Boot 3.3.5, Java 21, Spring Data JPA, PostgreSQL, Flyway, Jakarta Validation; тесты — Testcontainers + MockMvc (инфраструктура `support/AbstractIntegrationTest`, `support/TestAuth` уже существует).

**Предусловие:** ветка `feature/family-budget` (ответвлена от `feature/finance-core-and-goals`). Финансовое ядро (миграции V1–V7) на месте.

---

## Структура файлов

**Создаваемые — миграция:** `backend/src/main/resources/db/migration/V8__households.sql`

**Создаваемые — модуль `household`:**
- `.../household/domain/HouseholdRole.java` — enum OWNER/ADULT/CHILD
- `.../household/domain/Household.java` — сущность
- `.../household/repository/HouseholdRepository.java`
- `.../household/service/HouseholdService.java`
- `.../household/service/InviteCodeGenerator.java`
- `.../household/api/HouseholdController.java`
- `.../household/api/dto/HouseholdResponse.java`
- `.../household/api/dto/MemberResponse.java`
- `.../household/api/dto/CreateHouseholdRequest.java`
- `.../household/api/dto/JoinHouseholdRequest.java`
- `.../household/api/dto/UpdateMemberRoleRequest.java`

**Изменяемые:**
- `.../auth/domain/User.java` — поля `householdId`, `householdRole` + геттеры/хелперы
- `.../auth/repository/UserRepository.java` — `findByHouseholdId`

**Создаваемые — тесты:**
- `backend/src/test/java/com/aifb/platform/household/HouseholdServiceIT.java`
- `backend/src/test/java/com/aifb/platform/household/HouseholdApiIT.java`

Все команды `./gradlew` — из `backend/` с `JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home`. Docker запущен.

---

## Task 1: Миграция V8, сущность Household, роли, изменения User

**Files:**
- Create: `backend/src/main/resources/db/migration/V8__households.sql`
- Create: `.../household/domain/HouseholdRole.java`
- Create: `.../household/domain/Household.java`
- Create: `.../household/repository/HouseholdRepository.java`
- Modify: `.../auth/domain/User.java`
- Modify: `.../auth/repository/UserRepository.java`

- [ ] **Step 1: Создать миграцию V8**

Create `backend/src/main/resources/db/migration/V8__households.sql`:
```sql
CREATE TABLE households (
    id UUID PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    owner_user_id UUID NOT NULL REFERENCES users(id),
    invite_code VARCHAR(12) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT uk_households_invite_code UNIQUE (invite_code)
);

ALTER TABLE users
    ADD COLUMN household_id UUID REFERENCES households(id) ON DELETE SET NULL,
    ADD COLUMN household_role VARCHAR(10);

ALTER TABLE users
    ADD CONSTRAINT chk_users_household_role
        CHECK (household_role IN ('OWNER', 'ADULT', 'CHILD'));

ALTER TABLE users
    ADD CONSTRAINT chk_users_household_consistency
        CHECK ((household_id IS NULL) = (household_role IS NULL));

CREATE INDEX idx_users_household ON users (household_id) WHERE household_id IS NOT NULL;
```

- [ ] **Step 2: Создать enum `HouseholdRole`**

Create `.../household/domain/HouseholdRole.java`:
```java
package com.aifb.platform.household.domain;

public enum HouseholdRole {
    OWNER,
    ADULT,
    CHILD
}
```

- [ ] **Step 3: Создать сущность `Household`**

Create `.../household/domain/Household.java`:
```java
package com.aifb.platform.household.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "households")
public class Household extends BaseEntity {

    @Column(nullable = false, length = 120)
    private String name;

    @Column(name = "owner_user_id", nullable = false)
    private UUID ownerUserId;

    @Column(name = "invite_code", nullable = false, length = 12)
    private String inviteCode;

    protected Household() {
    }

    public Household(String name, UUID ownerUserId, String inviteCode) {
        this.id = UUID.randomUUID();
        this.name = name;
        this.ownerUserId = ownerUserId;
        this.inviteCode = inviteCode;
    }

    public String getName() { return name; }
    public UUID getOwnerUserId() { return ownerUserId; }
    public String getInviteCode() { return inviteCode; }

    public void setName(String name) { this.name = name; }
    public void setInviteCode(String inviteCode) { this.inviteCode = inviteCode; }
}
```

- [ ] **Step 4: Создать репозиторий `HouseholdRepository`**

Create `.../household/repository/HouseholdRepository.java`:
```java
package com.aifb.platform.household.repository;

import com.aifb.platform.household.domain.Household;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface HouseholdRepository extends JpaRepository<Household, UUID> {
    Optional<Household> findByInviteCode(String inviteCode);
    boolean existsByInviteCode(String inviteCode);
}
```

- [ ] **Step 5: Изменить сущность `User`**

In `.../auth/domain/User.java`:

(a) Add imports near the other `jakarta.persistence` imports:
```java
import com.aifb.platform.household.domain.HouseholdRole;
```

(b) Add fields after the `roles` field block (before `protected User()`):
```java
    @Column(name = "household_id")
    private UUID householdId;

    @Enumerated(EnumType.STRING)
    @Column(name = "household_role", length = 10)
    private HouseholdRole householdRole;
```
(`@Enumerated`, `@EnumType` are already imported in this file for the roles collection; `UUID` is imported.)

(c) Add getters + helpers after `getRoles()`:
```java
    public UUID getHouseholdId() { return householdId; }
    public HouseholdRole getHouseholdRole() { return householdRole; }
    public boolean isInHousehold() { return householdId != null; }

    public void joinHousehold(UUID householdId, HouseholdRole role) {
        this.householdId = householdId;
        this.householdRole = role;
    }

    public void setHouseholdRole(HouseholdRole role) {
        this.householdRole = role;
    }

    public void leaveHousehold() {
        this.householdId = null;
        this.householdRole = null;
    }
```

- [ ] **Step 6: Добавить метод в `UserRepository`**

In `.../auth/repository/UserRepository.java` add (imports `List`, `UUID` — add `import java.util.List;` if missing):
```java
    java.util.List<User> findByHouseholdId(UUID householdId);
```

- [ ] **Step 7: Проверить валидацию схемы**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.SmokeContextIT'
```
Expected: BUILD SUCCESSFUL. Flyway применяет V8, Hibernate `validate` подтверждает соответствие `Household` и новых колонок `User`.

- [ ] **Step 8: Commit**

```bash
git add backend/src/main/resources/db/migration/V8__households.sql backend/src/main/java/com/aifb/platform/household/domain backend/src/main/java/com/aifb/platform/household/repository backend/src/main/java/com/aifb/platform/auth/domain/User.java backend/src/main/java/com/aifb/platform/auth/repository/UserRepository.java
git commit -m "feat(household): миграция V8, сущность Household, роли и поля household в User"
```

---

## Task 2: DTO, генератор кода, создание/вступление/моя семья

**Files:**
- Create: `.../household/api/dto/MemberResponse.java`
- Create: `.../household/api/dto/HouseholdResponse.java`
- Create: `.../household/api/dto/CreateHouseholdRequest.java`
- Create: `.../household/api/dto/JoinHouseholdRequest.java`
- Create: `.../household/service/InviteCodeGenerator.java`
- Create: `.../household/service/HouseholdService.java`
- Test: `backend/src/test/java/com/aifb/platform/household/HouseholdServiceIT.java`

- [ ] **Step 1: Создать DTO**

Create `.../household/api/dto/MemberResponse.java`:
```java
package com.aifb.platform.household.api.dto;

import com.aifb.platform.auth.domain.User;

import java.util.UUID;

public record MemberResponse(UUID userId, String fullName, String role) {
    public static MemberResponse from(User u) {
        return new MemberResponse(
                u.getId(),
                u.getFullName(),
                u.getHouseholdRole() == null ? null : u.getHouseholdRole().name());
    }
}
```

Create `.../household/api/dto/HouseholdResponse.java`:
```java
package com.aifb.platform.household.api.dto;

import java.util.List;
import java.util.UUID;

public record HouseholdResponse(
        UUID id,
        String name,
        String inviteCode,
        String myRole,
        List<MemberResponse> members) {
}
```

Create `.../household/api/dto/CreateHouseholdRequest.java`:
```java
package com.aifb.platform.household.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateHouseholdRequest(@NotBlank @Size(max = 120) String name) {
}
```

Create `.../household/api/dto/JoinHouseholdRequest.java`:
```java
package com.aifb.platform.household.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record JoinHouseholdRequest(@NotBlank @Size(max = 12) String inviteCode) {
}
```

- [ ] **Step 2: Создать генератор кода**

Create `.../household/service/InviteCodeGenerator.java`:
```java
package com.aifb.platform.household.service;

import org.springframework.stereotype.Component;

import java.security.SecureRandom;

@Component
public class InviteCodeGenerator {

    private static final String ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private static final int LENGTH = 8;
    private final SecureRandom random = new SecureRandom();

    public String generate() {
        StringBuilder sb = new StringBuilder(LENGTH);
        for (int i = 0; i < LENGTH; i++) {
            sb.append(ALPHABET.charAt(random.nextInt(ALPHABET.length())));
        }
        return sb.toString();
    }
}
```

- [ ] **Step 3: Написать падающий тест сервиса**

Create `backend/src/test/java/com/aifb/platform/household/HouseholdServiceIT.java`:
```java
package com.aifb.platform.household;

import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.HouseholdResponse;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.service.HouseholdService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class HouseholdServiceIT extends AbstractIntegrationTest {

    @Autowired HouseholdService service;
    @Autowired TestAuth testAuth;

    @Test
    void createMakesCallerOwnerWithInviteCode() {
        UUID userId = testAuth.createUser().id();
        HouseholdResponse h = service.create(userId, new CreateHouseholdRequest("Семья"));
        assertThat(h.myRole()).isEqualTo("OWNER");
        assertThat(h.inviteCode()).isNotBlank();
        assertThat(h.members()).hasSize(1);
    }

    @Test
    void createTwiceForSameUserConflicts() {
        UUID userId = testAuth.createUser().id();
        service.create(userId, new CreateHouseholdRequest("Семья"));
        assertThatThrownBy(() -> service.create(userId, new CreateHouseholdRequest("Вторая")))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void joinByCodeAddsAdultMember() {
        UUID owner = testAuth.createUser().id();
        UUID joiner = testAuth.createUser().id();
        String code = service.create(owner, new CreateHouseholdRequest("Семья")).inviteCode();

        HouseholdResponse joined = service.join(joiner, new JoinHouseholdRequest(code));
        assertThat(joined.myRole()).isEqualTo("ADULT");
        assertThat(joined.members()).hasSize(2);
    }

    @Test
    void joinWithBadCodeNotFound() {
        UUID joiner = testAuth.createUser().id();
        assertThatThrownBy(() -> service.join(joiner, new JoinHouseholdRequest("BADCODE0")))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void joinWhenAlreadyInHouseholdConflicts() {
        UUID owner = testAuth.createUser().id();
        UUID joiner = testAuth.createUser().id();
        String code = service.create(owner, new CreateHouseholdRequest("Семья")).inviteCode();
        service.join(joiner, new JoinHouseholdRequest(code));
        assertThatThrownBy(() -> service.join(joiner, new JoinHouseholdRequest(code)))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void getMineHidesInviteCodeFromNonOwner() {
        UUID owner = testAuth.createUser().id();
        UUID joiner = testAuth.createUser().id();
        String code = service.create(owner, new CreateHouseholdRequest("Семья")).inviteCode();
        service.join(joiner, new JoinHouseholdRequest(code));

        assertThat(service.getMine(owner).inviteCode()).isEqualTo(code);
        assertThat(service.getMine(joiner).inviteCode()).isNull();
        assertThat(service.getMine(joiner).myRole()).isEqualTo("ADULT");
    }

    @Test
    void getMineWithoutHouseholdNotFound() {
        UUID userId = testAuth.createUser().id();
        assertThatThrownBy(() -> service.getMine(userId))
                .isInstanceOf(NotFoundException.class);
    }
}
```

- [ ] **Step 4: Запустить тест — убедиться, что НЕ компилируется/падает**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.household.HouseholdServiceIT'
```
Expected: FAIL — `HouseholdService` ещё не создан.

- [ ] **Step 5: Создать `HouseholdService` (создание/вступление/моя семья)**

Create `.../household/service/HouseholdService.java`:
```java
package com.aifb.platform.household.service;

import com.aifb.platform.auth.domain.User;
import com.aifb.platform.auth.repository.UserRepository;
import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.HouseholdResponse;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.api.dto.MemberResponse;
import com.aifb.platform.household.domain.Household;
import com.aifb.platform.household.domain.HouseholdRole;
import com.aifb.platform.household.repository.HouseholdRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class HouseholdService {

    private final HouseholdRepository householdRepository;
    private final UserRepository userRepository;
    private final InviteCodeGenerator codeGenerator;

    public HouseholdService(HouseholdRepository householdRepository,
                            UserRepository userRepository,
                            InviteCodeGenerator codeGenerator) {
        this.householdRepository = householdRepository;
        this.userRepository = userRepository;
        this.codeGenerator = codeGenerator;
    }

    @Transactional
    public HouseholdResponse create(UUID userId, CreateHouseholdRequest req) {
        User user = loadUser(userId);
        if (user.isInHousehold()) {
            throw new ConflictException("Вы уже состоите в семье");
        }
        Household household = new Household(req.name(), userId, uniqueCode());
        householdRepository.save(household);
        user.joinHousehold(household.getId(), HouseholdRole.OWNER);
        userRepository.save(user);
        return toResponse(household, user);
    }

    @Transactional
    public HouseholdResponse join(UUID userId, JoinHouseholdRequest req) {
        User user = loadUser(userId);
        if (user.isInHousehold()) {
            throw new ConflictException("Вы уже состоите в семье");
        }
        Household household = householdRepository.findByInviteCode(req.inviteCode())
                .orElseThrow(() -> new NotFoundException("Семья по коду не найдена"));
        user.joinHousehold(household.getId(), HouseholdRole.ADULT);
        userRepository.save(user);
        return toResponse(household, user);
    }

    @Transactional(readOnly = true)
    public HouseholdResponse getMine(UUID userId) {
        User user = loadUser(userId);
        if (!user.isInHousehold()) {
            throw new NotFoundException("Вы не состоите в семье");
        }
        Household household = householdRepository.findById(user.getHouseholdId())
                .orElseThrow(() -> new NotFoundException("Семья не найдена"));
        return toResponse(household, user);
    }

    private HouseholdResponse toResponse(Household household, User viewer) {
        List<MemberResponse> members = userRepository.findByHouseholdId(household.getId())
                .stream().map(MemberResponse::from).toList();
        boolean isOwner = viewer.getHouseholdRole() == HouseholdRole.OWNER;
        return new HouseholdResponse(
                household.getId(),
                household.getName(),
                isOwner ? household.getInviteCode() : null,
                viewer.getHouseholdRole() == null ? null : viewer.getHouseholdRole().name(),
                members);
    }

    private String uniqueCode() {
        String code;
        do {
            code = codeGenerator.generate();
        } while (householdRepository.existsByInviteCode(code));
        return code;
    }

    User loadUser(UUID userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Пользователь не найден"));
    }
}
```

- [ ] **Step 6: Запустить тест — убедиться, что проходит**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.household.HouseholdServiceIT'
```
Expected: BUILD SUCCESSFUL, 7 тестов passed.

- [ ] **Step 7: Commit**

```bash
git add backend/src/main/java/com/aifb/platform/household/api/dto backend/src/main/java/com/aifb/platform/household/service backend/src/test/java/com/aifb/platform/household/HouseholdServiceIT.java
git commit -m "feat(household): создание/вступление/моя семья с генератором кода и тестами"
```

---

## Task 3: Управление участниками (роли, удаление, выход, роспуск, код)

**Files:**
- Create: `.../household/api/dto/UpdateMemberRoleRequest.java`
- Modify: `.../household/service/HouseholdService.java`
- Test: `backend/src/test/java/com/aifb/platform/household/HouseholdServiceIT.java` (дополнить)

- [ ] **Step 1: Создать DTO смены роли**

Create `.../household/api/dto/UpdateMemberRoleRequest.java`:
```java
package com.aifb.platform.household.api.dto;

import com.aifb.platform.household.domain.HouseholdRole;
import jakarta.validation.constraints.NotNull;

public record UpdateMemberRoleRequest(@NotNull HouseholdRole role) {
}
```

- [ ] **Step 2: Дополнить тест сервиса новыми сценариями**

Append these tests inside the `HouseholdServiceIT` class in
`backend/src/test/java/com/aifb/platform/household/HouseholdServiceIT.java`
(add imports `com.aifb.platform.common.exception.ForbiddenException` and
`com.aifb.platform.household.domain.HouseholdRole`):
```java
    @Test
    void ownerChangesMemberRoleToChild() {
        UUID owner = testAuth.createUser().id();
        UUID joiner = testAuth.createUser().id();
        String code = service.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        service.join(joiner, new JoinHouseholdRequest(code));

        service.changeRole(owner, joiner, HouseholdRole.CHILD);
        assertThat(service.getMine(joiner).myRole()).isEqualTo("CHILD");
    }

    @Test
    void nonOwnerCannotChangeRole() {
        UUID owner = testAuth.createUser().id();
        UUID joiner = testAuth.createUser().id();
        String code = service.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        service.join(joiner, new JoinHouseholdRequest(code));
        assertThatThrownBy(() -> service.changeRole(joiner, owner, HouseholdRole.CHILD))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void ownerCannotChangeOwnRole() {
        UUID owner = testAuth.createUser().id();
        assertThatThrownBy(() -> service.changeRole(owner, owner, HouseholdRole.ADULT))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void cannotPromoteToSecondOwner() {
        UUID owner = testAuth.createUser().id();
        UUID joiner = testAuth.createUser().id();
        String code = service.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        service.join(joiner, new JoinHouseholdRequest(code));
        assertThatThrownBy(() -> service.changeRole(owner, joiner, HouseholdRole.OWNER))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void ownerRemovesMember() {
        UUID owner = testAuth.createUser().id();
        UUID joiner = testAuth.createUser().id();
        String code = service.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        service.join(joiner, new JoinHouseholdRequest(code));

        service.removeMember(owner, joiner);
        assertThat(service.getMine(owner).members()).hasSize(1);
        assertThatThrownBy(() -> service.getMine(joiner))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void memberLeaves() {
        UUID owner = testAuth.createUser().id();
        UUID joiner = testAuth.createUser().id();
        String code = service.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        service.join(joiner, new JoinHouseholdRequest(code));

        service.leave(joiner);
        assertThatThrownBy(() -> service.getMine(joiner))
                .isInstanceOf(NotFoundException.class);
        assertThat(service.getMine(owner).members()).hasSize(1);
    }

    @Test
    void ownerCannotLeaveMustDisband() {
        UUID owner = testAuth.createUser().id();
        service.create(owner, new CreateHouseholdRequest("С"));
        assertThatThrownBy(() -> service.leave(owner))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void ownerDisbandsHousehold() {
        UUID owner = testAuth.createUser().id();
        UUID joiner = testAuth.createUser().id();
        String code = service.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        service.join(joiner, new JoinHouseholdRequest(code));

        service.disband(owner);
        assertThatThrownBy(() -> service.getMine(owner)).isInstanceOf(NotFoundException.class);
        assertThatThrownBy(() -> service.getMine(joiner)).isInstanceOf(NotFoundException.class);
    }

    @Test
    void rotateCodeChangesInviteCode() {
        UUID owner = testAuth.createUser().id();
        String oldCode = service.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        String newCode = service.rotateCode(owner).inviteCode();
        assertThat(newCode).isNotEqualTo(oldCode).isNotBlank();
    }
```

- [ ] **Step 3: Запустить тест — убедиться, что НЕ компилируется/падает**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.household.HouseholdServiceIT'
```
Expected: FAIL — методы `changeRole`/`removeMember`/`leave`/`disband`/`rotateCode` ещё не созданы.

- [ ] **Step 4: Дополнить `HouseholdService` методами управления**

Add these methods inside `HouseholdService` (before the private helpers).
Add imports `com.aifb.platform.common.exception.ForbiddenException` and `java.util.List` (List already imported):
```java
    @Transactional
    public HouseholdResponse changeRole(UUID actorId, UUID targetUserId, HouseholdRole role) {
        User actor = requireOwner(actorId);
        if (actorId.equals(targetUserId)) {
            throw new ForbiddenException("Нельзя менять собственную роль");
        }
        if (role == HouseholdRole.OWNER) {
            throw new ForbiddenException("В семье может быть только один владелец");
        }
        User target = sameHouseholdMember(actor, targetUserId);
        target.setHouseholdRole(role);
        userRepository.save(target);
        Household household = householdRepository.findById(actor.getHouseholdId()).orElseThrow();
        return toResponse(household, actor);
    }

    @Transactional
    public void removeMember(UUID actorId, UUID targetUserId) {
        User actor = requireOwner(actorId);
        if (actorId.equals(targetUserId)) {
            throw new ForbiddenException("Владелец не может удалить себя; распустите семью");
        }
        User target = sameHouseholdMember(actor, targetUserId);
        target.leaveHousehold();
        userRepository.save(target);
    }

    @Transactional
    public void leave(UUID userId) {
        User user = loadUser(userId);
        if (!user.isInHousehold()) {
            throw new NotFoundException("Вы не состоите в семье");
        }
        if (user.getHouseholdRole() == HouseholdRole.OWNER) {
            throw new ForbiddenException("Владелец не может выйти; распустите семью");
        }
        user.leaveHousehold();
        userRepository.save(user);
    }

    @Transactional
    public void disband(UUID actorId) {
        User actor = requireOwner(actorId);
        UUID householdId = actor.getHouseholdId();
        for (User member : userRepository.findByHouseholdId(householdId)) {
            member.leaveHousehold();
            userRepository.save(member);
        }
        householdRepository.deleteById(householdId);
    }

    @Transactional
    public HouseholdResponse rotateCode(UUID actorId) {
        User actor = requireOwner(actorId);
        Household household = householdRepository.findById(actor.getHouseholdId())
                .orElseThrow(() -> new NotFoundException("Семья не найдена"));
        household.setInviteCode(uniqueCode());
        householdRepository.save(household);
        return toResponse(household, actor);
    }

    private User requireOwner(UUID userId) {
        User user = loadUser(userId);
        if (!user.isInHousehold() || user.getHouseholdRole() != HouseholdRole.OWNER) {
            throw new ForbiddenException("Только владелец семьи может выполнить это действие");
        }
        return user;
    }

    private User sameHouseholdMember(User actor, UUID targetUserId) {
        User target = loadUser(targetUserId);
        if (!actor.getHouseholdId().equals(target.getHouseholdId())) {
            throw new NotFoundException("Участник не найден в вашей семье");
        }
        return target;
    }
```

- [ ] **Step 5: Запустить тест — убедиться, что проходит**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.household.HouseholdServiceIT'
```
Expected: BUILD SUCCESSFUL, 16 тестов passed (7 из Task 2 + 9 новых).

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/com/aifb/platform/household/api/dto/UpdateMemberRoleRequest.java backend/src/main/java/com/aifb/platform/household/service/HouseholdService.java backend/src/test/java/com/aifb/platform/household/HouseholdServiceIT.java
git commit -m "feat(household): управление участниками (роли, удаление, выход, роспуск, код) с тестами"
```

---

## Task 4: REST-контроллер и web-тесты

**Files:**
- Create: `.../household/api/HouseholdController.java`
- Test: `backend/src/test/java/com/aifb/platform/household/HouseholdApiIT.java`

- [ ] **Step 1: Написать падающий web-тест**

Create `backend/src/test/java/com/aifb/platform/household/HouseholdApiIT.java`:
```java
package com.aifb.platform.household;

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

class HouseholdApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired ObjectMapper objectMapper;

    @Test
    void createJoinFlow() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        MvcResult created = mockMvc.perform(post("/api/v1/households")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Семья\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.myRole").value("OWNER"))
                .andExpect(jsonPath("$.data.inviteCode").isNotEmpty())
                .andReturn();
        String code = objectMapper.readTree(created.getResponse().getContentAsString())
                .path("data").path("inviteCode").asText();

        TestAuth.AuthedUser joiner = testAuth.createUser();
        mockMvc.perform(post("/api/v1/households/join")
                        .header(HttpHeaders.AUTHORIZATION, joiner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"inviteCode\":\"" + code + "\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.myRole").value("ADULT"))
                .andExpect(jsonPath("$.data.members.length()").value(2));
    }

    @Test
    void getMineRequiresAuth() throws Exception {
        mockMvc.perform(get("/api/v1/households/me"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void getMineWithoutHouseholdReturns404() throws Exception {
        TestAuth.AuthedUser u = testAuth.createUser();
        mockMvc.perform(get("/api/v1/households/me")
                        .header(HttpHeaders.AUTHORIZATION, u.bearer()))
                .andExpect(status().isNotFound());
    }
}
```

- [ ] **Step 2: Запустить тест — убедиться, что падает**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.household.HouseholdApiIT'
```
Expected: FAIL — контроллера нет.

- [ ] **Step 3: Создать `HouseholdController`**

Create `.../household/api/HouseholdController.java`:
```java
package com.aifb.platform.household.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.HouseholdResponse;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.api.dto.UpdateMemberRoleRequest;
import com.aifb.platform.household.service.HouseholdService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/households")
public class HouseholdController {

    private final HouseholdService service;

    public HouseholdController(HouseholdService service) {
        this.service = service;
    }

    @PostMapping
    public ApiResponse<HouseholdResponse> create(
            @CurrentUser AuthPrincipal principal,
            @Valid @RequestBody CreateHouseholdRequest request) {
        return ApiResponse.ok(service.create(principal.userId(), request));
    }

    @GetMapping("/me")
    public ApiResponse<HouseholdResponse> me(@CurrentUser AuthPrincipal principal) {
        return ApiResponse.ok(service.getMine(principal.userId()));
    }

    @PostMapping("/join")
    public ApiResponse<HouseholdResponse> join(
            @CurrentUser AuthPrincipal principal,
            @Valid @RequestBody JoinHouseholdRequest request) {
        return ApiResponse.ok(service.join(principal.userId(), request));
    }

    @PutMapping("/members/{userId}/role")
    public ApiResponse<HouseholdResponse> changeRole(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID userId,
            @Valid @RequestBody UpdateMemberRoleRequest request) {
        return ApiResponse.ok(service.changeRole(principal.userId(), userId, request.role()));
    }

    @DeleteMapping("/members/{userId}")
    public ApiResponse<Void> removeMember(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID userId) {
        service.removeMember(principal.userId(), userId);
        return ApiResponse.ok(null);
    }

    @PostMapping("/leave")
    public ApiResponse<Void> leave(@CurrentUser AuthPrincipal principal) {
        service.leave(principal.userId());
        return ApiResponse.ok(null);
    }

    @DeleteMapping
    public ApiResponse<Void> disband(@CurrentUser AuthPrincipal principal) {
        service.disband(principal.userId());
        return ApiResponse.ok(null);
    }

    @PostMapping("/rotate-code")
    public ApiResponse<HouseholdResponse> rotateCode(@CurrentUser AuthPrincipal principal) {
        return ApiResponse.ok(service.rotateCode(principal.userId()));
    }
}
```

- [ ] **Step 4: Запустить тест — убедиться, что проходит**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.household.HouseholdApiIT'
```
Expected: BUILD SUCCESSFUL, 3 теста passed.

- [ ] **Step 5: Прогнать весь набор**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test
```
Expected: BUILD SUCCESSFUL, все тесты (финансовое ядро + household) passed. Сообщить итоговое число.

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/com/aifb/platform/household/api/HouseholdController.java backend/src/test/java/com/aifb/platform/household/HouseholdApiIT.java
git commit -m "feat(household): REST-контроллер семьи с web-тестами"
```

---

## Self-review (выполнено при написании плана)

- **Покрытие спеки:** таблица `households` + поля в `users` (V8), роли OWNER/ADULT/CHILD, эндпоинты
  create/join/me/role/remove/leave/disband/rotate-code, скрытие `inviteCode` от не-OWNER, вступление
  по умолчанию ADULT, запрет второго OWNER, запрет выхода/смены роли владельца — все из секций спеки
  «households / users / Эндпоинты / Матрица прав (часть про управление участниками)». Scope финансов
  и by-member — в Плане 2 (вне этого плана); каскад при роспуске семейных финансовых строк — в Плане 2
  (FK добавляются вместе с `household_id` в V9). В Плане 1 роспуск только отвязывает участников и удаляет household.
- **Плейсхолдеры:** отсутствуют — каждый шаг содержит полный код или точную команду с ожидаемым результатом.
- **Согласованность типов:** `HouseholdRole` объявлен один раз (Task 1) и используется в `User`, DTO,
  сервисе, контроллере единообразно. Сигнатуры `service.create/join/getMine/changeRole/removeMember/
  leave/disband/rotateCode` совпадают между объявлением (Tasks 2–3) и вызовами в тестах и контроллере (Task 4).
  `loadUser` имеет package-private видимость — переиспользуется методами в обоих наборах.
- **Заметка:** `getMine` для не-членов бросает `NotFoundException` → HTTP 404 (см. web-тест `getMineWithoutHouseholdReturns404`).
