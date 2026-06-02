# Password Recovery (dev-режим) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Дать пользователю восстановить пароль: запросить 6-значный код по email и задать новый пароль; в dev-режиме код возвращается в ответе и показывается на экране (SMTP не настроен).

**Architecture:** Бэкенд — отдельный `PasswordResetService` + таблица `password_reset_codes` (BCrypt-хеш кода, TTL 30 мин, одноразовый), два публичных эндпоинта в `AuthController`. Фронт — расширяем существующие `ForgotPasswordController`/`ForgotPasswordState` под один экран в два шага и реализуем `ForgotPasswordPage` вместо заглушки.

**Tech Stack:** Spring Boot 3.3.5 / Java 21 / Flyway / JPA / Testcontainers + MockMvc; Flutter / Riverpod / freezed / go_router / mocktail.

**Spec:** `docs/superpowers/specs/2026-06-02-password-recovery-design.md`

**Окружение:**
- Backend: запускать из каталога `backend/`, `JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home`.
- Frontend: каталог `frontend/`.
- Базовый путь API — `/api/v1/auth`. Frontend baseUrl уже `http://localhost:9090/api/v1`.
- Правило пароля (как при регистрации): 8–72 символа, минимум одна буква и одна цифра.

---

## File Structure

**Backend (создать):**
- `backend/src/main/resources/db/migration/V13__password_reset_codes.sql`
- `backend/.../auth/domain/PasswordResetCode.java`
- `backend/.../auth/repository/PasswordResetCodeRepository.java`
- `backend/.../auth/service/PasswordResetService.java`
- `backend/.../auth/api/dto/ForgotPasswordRequest.java`
- `backend/.../auth/api/dto/ForgotPasswordResponse.java`
- `backend/.../auth/api/dto/ResetPasswordRequest.java`
- `backend/src/test/java/com/aifb/platform/auth/PasswordResetApiIT.java`
- `backend/src/test/java/com/aifb/platform/auth/PasswordResetExpiryIT.java`

**Backend (изменить):**
- `backend/.../common/exception/ErrorCode.java` — добавить `AUTH_RESET_CODE_INVALID`
- `backend/.../auth/domain/User.java` — добавить `changePassword(String)`
- `backend/.../auth/api/AuthController.java` — добавить два эндпоинта

**Frontend (создать):**
- `frontend/lib/features/auth/presentation/pages/forgot_password_page.dart`
- `frontend/test/features/auth/auth_repository_test.dart`
- `frontend/test/features/auth/forgot_password_controller_test.dart`

**Frontend (изменить):**
- `frontend/lib/features/auth/data/datasources/auth_remote_data_source.dart`
- `frontend/lib/features/auth/data/repositories/auth_repository_impl.dart`
- `frontend/lib/features/auth/domain/repositories/auth_repository.dart`
- `frontend/lib/features/auth/presentation/state/forgot_password_state.dart` (+ регенерация `.freezed.dart`)
- `frontend/lib/features/auth/presentation/controllers/forgot_password_controller.dart`
- `frontend/lib/app/router/app_router.dart` — заменить `_Placeholder` на `ForgotPasswordPage`

**Примечание по стилю:** файлы в `lib/features/auth/**` (data/domain/controllers/state) используют **относительные** импорты — следуйте этому стилю в них. Файл-страница `forgot_password_page.dart` и тесты следуют стилю соседей (`login_page.dart`, `budgets_repository_test.dart`) — `package:`-импорты.

---

## Task 1: Backend — инфраструктура хранения кодов

**Files:**
- Modify: `backend/src/main/java/com/aifb/platform/common/exception/ErrorCode.java`
- Modify: `backend/src/main/java/com/aifb/platform/auth/domain/User.java`
- Create: `backend/src/main/resources/db/migration/V13__password_reset_codes.sql`
- Create: `backend/src/main/java/com/aifb/platform/auth/domain/PasswordResetCode.java`
- Create: `backend/src/main/java/com/aifb/platform/auth/repository/PasswordResetCodeRepository.java`

- [ ] **Step 1: Добавить код ошибки в `ErrorCode`**

В `ErrorCode.java` в секцию `// Auth` (после `AUTH_USER_BLOCKED`) добавить новую константу. Изменить строку:

```java
    AUTH_USER_BLOCKED("AUTH_USER_BLOCKED", HttpStatus.FORBIDDEN);
```

на:

```java
    AUTH_USER_BLOCKED("AUTH_USER_BLOCKED", HttpStatus.FORBIDDEN),
    AUTH_RESET_CODE_INVALID("AUTH_RESET_CODE_INVALID", HttpStatus.BAD_REQUEST);
```

- [ ] **Step 2: Добавить `changePassword` в `User`**

В `User.java` после метода `incrementTokenVersion()` добавить:

```java
    public void changePassword(String newPasswordHash) {
        this.passwordHash = newPasswordHash;
    }
```

- [ ] **Step 3: Создать миграцию `V13__password_reset_codes.sql`**

```sql
CREATE TABLE password_reset_codes (
    id          UUID PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code_hash   VARCHAR(255) NOT NULL,
    expires_at  TIMESTAMPTZ NOT NULL,
    used_at     TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_password_reset_codes_user ON password_reset_codes (user_id);
```

- [ ] **Step 4: Создать сущность `PasswordResetCode`**

`PasswordResetCode.java` — самостоятельная сущность (НЕ наследует `BaseEntity`, т.к. таблица без `updated_at`/`version`):

```java
package com.aifb.platform.auth.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "password_reset_codes")
public class PasswordResetCode {

    @Id
    @JdbcTypeCode(SqlTypes.UUID)
    @Column(columnDefinition = "uuid", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "code_hash", nullable = false, length = 255)
    private String codeHash;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "used_at")
    private Instant usedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected PasswordResetCode() {
    }

    public PasswordResetCode(UUID userId, String codeHash, Instant expiresAt, Instant createdAt) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.codeHash = codeHash;
        this.expiresAt = expiresAt;
        this.createdAt = createdAt;
    }

    public UUID getId() { return id; }
    public UUID getUserId() { return userId; }
    public String getCodeHash() { return codeHash; }
    public Instant getExpiresAt() { return expiresAt; }
    public Instant getUsedAt() { return usedAt; }
    public Instant getCreatedAt() { return createdAt; }

    public void markUsed(Instant now) {
        this.usedAt = now;
    }
}
```

- [ ] **Step 5: Создать репозиторий `PasswordResetCodeRepository`**

```java
package com.aifb.platform.auth.repository;

import com.aifb.platform.auth.domain.PasswordResetCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

public interface PasswordResetCodeRepository extends JpaRepository<PasswordResetCode, UUID> {

    Optional<PasswordResetCode> findFirstByUserIdAndUsedAtIsNullOrderByCreatedAtDesc(UUID userId);

    @Modifying
    @Query("update PasswordResetCode c set c.usedAt = :now "
            + "where c.userId = :userId and c.usedAt is null")
    void markAllActiveUsed(@Param("userId") UUID userId, @Param("now") Instant now);
}
```

- [ ] **Step 6: Скомпилировать и прогнать smoke-тест (миграция применяется, контекст поднимается)**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.SmokeContextIT'
```
Expected: PASS (Flyway применяет V13, Hibernate валидирует таблицу `password_reset_codes`).

- [ ] **Step 7: Commit**

```bash
git add backend/src/main/resources/db/migration/V13__password_reset_codes.sql \
        backend/src/main/java/com/aifb/platform/auth/domain/PasswordResetCode.java \
        backend/src/main/java/com/aifb/platform/auth/repository/PasswordResetCodeRepository.java \
        backend/src/main/java/com/aifb/platform/common/exception/ErrorCode.java \
        backend/src/main/java/com/aifb/platform/auth/domain/User.java
git commit -m "feat(auth): хранилище кодов сброса пароля (миграция V13 + сущность + репозиторий)"
```

---

## Task 2: Backend — сервис, DTO, эндпоинты

**Files:**
- Create: `backend/src/main/java/com/aifb/platform/auth/api/dto/ForgotPasswordRequest.java`
- Create: `backend/src/main/java/com/aifb/platform/auth/api/dto/ForgotPasswordResponse.java`
- Create: `backend/src/main/java/com/aifb/platform/auth/api/dto/ResetPasswordRequest.java`
- Create: `backend/src/main/java/com/aifb/platform/auth/service/PasswordResetService.java`
- Modify: `backend/src/main/java/com/aifb/platform/auth/api/AuthController.java`
- Test: `backend/src/test/java/com/aifb/platform/auth/PasswordResetApiIT.java`

- [ ] **Step 1: Написать падающий интеграционный тест `PasswordResetApiIT`**

```java
package com.aifb.platform.auth;

import com.aifb.platform.support.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MvcResult;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class PasswordResetApiIT extends AbstractIntegrationTest {

    @Autowired ObjectMapper objectMapper;

    private String register(String email) throws Exception {
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"fullName\":\"Test User\",\"email\":\"" + email
                                + "\",\"password\":\"oldpass123\"}"))
                .andExpect(status().isCreated());
        return email;
    }

    private String requestCode(String email) throws Exception {
        MvcResult res = mockMvc.perform(post("/api/v1/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\"}"))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode body = objectMapper.readTree(res.getResponse().getContentAsString());
        return body.path("data").path("devCode").asText(null);
    }

    @Test
    void forgotReturnsDevCodeForKnownEmail() throws Exception {
        String email = register("known-" + UUID.randomUUID() + "@example.com");
        String code = requestCode(email);
        assertThat(code).isNotNull().hasSize(6).matches("\\d{6}");
    }

    @Test
    void forgotReturnsNullDevCodeForUnknownEmail() throws Exception {
        mockMvc.perform(post("/api/v1/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"nobody-" + UUID.randomUUID() + "@example.com\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.devCode").doesNotExist());
    }

    @Test
    void resetWithValidCodeChangesPassword() throws Exception {
        String email = register("reset-" + UUID.randomUUID() + "@example.com");
        String code = requestCode(email);

        mockMvc.perform(post("/api/v1/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"code\":\"" + code
                                + "\",\"newPassword\":\"newpass123\"}"))
                .andExpect(status().isOk());

        // новый пароль работает
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"newpass123\"}"))
                .andExpect(status().isOk());
        // старый пароль отклоняется
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"oldpass123\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void codeIsSingleUse() throws Exception {
        String email = register("single-" + UUID.randomUUID() + "@example.com");
        String code = requestCode(email);
        mockMvc.perform(post("/api/v1/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"code\":\"" + code
                                + "\",\"newPassword\":\"newpass123\"}"))
                .andExpect(status().isOk());
        // повторный сброс тем же кодом — 400
        mockMvc.perform(post("/api/v1/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"code\":\"" + code
                                + "\",\"newPassword\":\"another123\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("AUTH_RESET_CODE_INVALID"));
    }

    @Test
    void resetWithWrongCodeFails() throws Exception {
        String email = register("wrong-" + UUID.randomUUID() + "@example.com");
        requestCode(email);
        mockMvc.perform(post("/api/v1/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"code\":\"000000\","
                                + "\"newPassword\":\"newpass123\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("AUTH_RESET_CODE_INVALID"));
    }

    @Test
    void newRequestInvalidatesPreviousCode() throws Exception {
        String email = register("regen-" + UUID.randomUUID() + "@example.com");
        String first = requestCode(email);
        String second = requestCode(email);
        assertThat(second).isNotEqualTo(first);
        // старый код больше не валиден
        mockMvc.perform(post("/api/v1/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"code\":\"" + first
                                + "\",\"newPassword\":\"newpass123\"}"))
                .andExpect(status().isBadRequest());
        // новый код работает
        mockMvc.perform(post("/api/v1/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"code\":\"" + second
                                + "\",\"newPassword\":\"newpass123\"}"))
                .andExpect(status().isOk());
    }
}
```

> Примечание: точная форма поля кода ошибки — `$.error.code`. Если в проекте конверт ошибки иной, свериться с `GlobalExceptionHandler`/существующим тестом ошибок и поправить jsonPath (значение `AUTH_RESET_CODE_INVALID` остаётся).

- [ ] **Step 2: Прогнать тест — убедиться, что не компилируется/падает (red)**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.auth.PasswordResetApiIT'
```
Expected: FAIL (нет эндпоинтов `/forgot-password`, `/reset-password` → 404/ошибка компиляции отсутствующих классов нет, но эндпоинты вернут 404/405).

- [ ] **Step 3: Создать DTO `ForgotPasswordRequest`**

```java
package com.aifb.platform.auth.api.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ForgotPasswordRequest(
        @NotBlank(message = "Email is required")
        @Email(message = "Email must be valid")
        @Size(max = 320, message = "Email is too long")
        String email) {
}
```

- [ ] **Step 4: Создать DTO `ForgotPasswordResponse`**

```java
package com.aifb.platform.auth.api.dto;

import java.time.Instant;

/**
 * Ответ на запрос кода сброса. Поле {@code devCode} существует только потому,
 * что SMTP не настроен (dev-режим): код возвращается клиенту напрямую. В проде
 * код отправляется письмом, а {@code devCode}/{@code expiresAt} становятся null.
 */
public record ForgotPasswordResponse(String devCode, Instant expiresAt) {
}
```

- [ ] **Step 5: Создать DTO `ResetPasswordRequest`**

```java
package com.aifb.platform.auth.api.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record ResetPasswordRequest(
        @NotBlank(message = "Email is required")
        @Email(message = "Email must be valid")
        String email,

        @NotBlank(message = "Code is required")
        @Pattern(regexp = "^\\d{6}$", message = "Code must be 6 digits")
        String code,

        @NotBlank(message = "Password is required")
        @Size(min = 8, max = 72, message = "Password must be between 8 and 72 characters")
        @Pattern(
                regexp = "^(?=.*[A-Za-z])(?=.*\\d).+$",
                message = "Password must contain at least one letter and one number")
        String newPassword) {
}
```

- [ ] **Step 6: Создать `PasswordResetService`**

```java
package com.aifb.platform.auth.service;

import com.aifb.platform.auth.api.dto.ForgotPasswordResponse;
import com.aifb.platform.auth.domain.PasswordResetCode;
import com.aifb.platform.auth.domain.User;
import com.aifb.platform.auth.repository.PasswordResetCodeRepository;
import com.aifb.platform.auth.repository.UserRepository;
import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.common.exception.ErrorCode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.Optional;

@Service
public class PasswordResetService {

    private final UserRepository userRepository;
    private final PasswordResetCodeRepository codeRepository;
    private final PasswordEncoder passwordEncoder;
    private final RefreshTokenService refreshTokenService;
    private final Duration resetTtl;
    private final SecureRandom random = new SecureRandom();

    public PasswordResetService(UserRepository userRepository,
                                PasswordResetCodeRepository codeRepository,
                                PasswordEncoder passwordEncoder,
                                RefreshTokenService refreshTokenService,
                                @Value("${aifb.verification.password-reset-ttl}") Duration resetTtl) {
        this.userRepository = userRepository;
        this.codeRepository = codeRepository;
        this.passwordEncoder = passwordEncoder;
        this.refreshTokenService = refreshTokenService;
        this.resetTtl = resetTtl;
    }

    @Transactional
    public ForgotPasswordResponse forgotPassword(String rawEmail) {
        Optional<User> userOpt = userRepository.findByEmailIgnoreCase(normalize(rawEmail));
        if (userOpt.isEmpty()) {
            return new ForgotPasswordResponse(null, null);
        }
        User user = userOpt.get();
        Instant now = Instant.now();
        codeRepository.markAllActiveUsed(user.getId(), now);
        String code = String.format("%06d", random.nextInt(1_000_000));
        Instant expiresAt = now.plus(resetTtl);
        codeRepository.save(new PasswordResetCode(
                user.getId(), passwordEncoder.encode(code), expiresAt, now));
        return new ForgotPasswordResponse(code, expiresAt);
    }

    @Transactional
    public void reset(String rawEmail, String code, String newPassword) {
        User user = userRepository.findByEmailIgnoreCase(normalize(rawEmail))
                .orElseThrow(this::invalidCode);
        PasswordResetCode entity = codeRepository
                .findFirstByUserIdAndUsedAtIsNullOrderByCreatedAtDesc(user.getId())
                .orElseThrow(this::invalidCode);
        Instant now = Instant.now();
        if (now.isAfter(entity.getExpiresAt()) || !passwordEncoder.matches(code, entity.getCodeHash())) {
            throw invalidCode();
        }
        user.changePassword(passwordEncoder.encode(newPassword));
        user.incrementTokenVersion();
        refreshTokenService.revokeAll(user);
        entity.markUsed(now);
    }

    private static String normalize(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private DomainException invalidCode() {
        return new DomainException(ErrorCode.AUTH_RESET_CODE_INVALID, "Invalid or expired reset code");
    }
}
```

- [ ] **Step 7: Добавить эндпоинты в `AuthController`**

Добавить импорты (рядом с существующими):

```java
import com.aifb.platform.auth.api.dto.ForgotPasswordRequest;
import com.aifb.platform.auth.api.dto.ForgotPasswordResponse;
import com.aifb.platform.auth.api.dto.ResetPasswordRequest;
import com.aifb.platform.auth.service.PasswordResetService;
```

Внедрить сервис в конструктор. Заменить поле и конструктор:

```java
    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }
```

на:

```java
    private final AuthService authService;
    private final PasswordResetService passwordResetService;

    public AuthController(AuthService authService, PasswordResetService passwordResetService) {
        this.authService = authService;
        this.passwordResetService = passwordResetService;
    }
```

Добавить два метода (например, после `logoutAll`):

```java
    @PostMapping("/forgot-password")
    public ApiResponse<ForgotPasswordResponse> forgotPassword(
            @Valid @RequestBody ForgotPasswordRequest request) {
        return ApiResponse.ok(passwordResetService.forgotPassword(request.email()));
    }

    @PostMapping("/reset-password")
    public ApiResponse<Void> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        passwordResetService.reset(request.email(), request.code(), request.newPassword());
        return ApiResponse.ok(null);
    }
```

> Эти пути публичные — убедиться, что в security-конфиге `/api/v1/auth/**` уже открыт (как `register`/`login`). Если правила перечислены поимённо, добавить `forgot-password` и `reset-password`. Проверить класс с `SecurityFilterChain`.

- [ ] **Step 8: Прогнать тест — green**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.auth.PasswordResetApiIT'
```
Expected: PASS (6 тестов).

- [ ] **Step 9: Commit**

```bash
git add backend/src/main/java/com/aifb/platform/auth/api/dto/ForgotPasswordRequest.java \
        backend/src/main/java/com/aifb/platform/auth/api/dto/ForgotPasswordResponse.java \
        backend/src/main/java/com/aifb/platform/auth/api/dto/ResetPasswordRequest.java \
        backend/src/main/java/com/aifb/platform/auth/service/PasswordResetService.java \
        backend/src/main/java/com/aifb/platform/auth/api/AuthController.java \
        backend/src/test/java/com/aifb/platform/auth/PasswordResetApiIT.java
git commit -m "feat(auth): эндпоинты forgot-password/reset-password (dev-режим, код в ответе)"
```

---

## Task 3: Backend — тест истечения кода (TTL)

**Files:**
- Test: `backend/src/test/java/com/aifb/platform/auth/PasswordResetExpiryIT.java`

- [ ] **Step 1: Написать тест с нулевым TTL (код истекает сразу)**

Отдельный класс с `@TestPropertySource`, переопределяющим TTL на `PT0S`, — тогда `expiresAt == момент создания`, а проверка `now.isAfter(expiresAt)` при сбросе истинна.

```java
package com.aifb.platform.auth;

import com.aifb.platform.support.AbstractIntegrationTest;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MvcResult;

import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@TestPropertySource(properties = "aifb.verification.password-reset-ttl=PT0S")
class PasswordResetExpiryIT extends AbstractIntegrationTest {

    @Autowired ObjectMapper objectMapper;

    @Test
    void expiredCodeIsRejected() throws Exception {
        String email = "expire-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"fullName\":\"Test User\",\"email\":\"" + email
                                + "\",\"password\":\"oldpass123\"}"))
                .andExpect(status().isCreated());

        MvcResult res = mockMvc.perform(post("/api/v1/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\"}"))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode body = objectMapper.readTree(res.getResponse().getContentAsString());
        String code = body.path("data").path("devCode").asText(null);

        mockMvc.perform(post("/api/v1/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"code\":\"" + code
                                + "\",\"newPassword\":\"newpass123\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("AUTH_RESET_CODE_INVALID"));
    }
}
```

- [ ] **Step 2: Прогнать тест — green**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests 'com.aifb.platform.auth.PasswordResetExpiryIT'
```
Expected: PASS.

- [ ] **Step 3: Прогнать весь бэкенд-набор (регрессия)**

Run:
```bash
cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test
```
Expected: PASS (прежние + новые тесты зелёные).

- [ ] **Step 4: Commit**

```bash
git add backend/src/test/java/com/aifb/platform/auth/PasswordResetExpiryIT.java
git commit -m "test(auth): сброс отклоняет истёкший код (TTL=PT0S)"
```

---

## Task 4: Frontend — data-слой

**Files:**
- Modify: `frontend/lib/features/auth/data/datasources/auth_remote_data_source.dart`
- Modify: `frontend/lib/features/auth/domain/repositories/auth_repository.dart`
- Modify: `frontend/lib/features/auth/data/repositories/auth_repository_impl.dart`
- Test: `frontend/test/features/auth/auth_repository_test.dart`

- [ ] **Step 1: Написать падающий тест репозитория**

`frontend/test/features/auth/auth_repository_test.dart`:

```dart
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/core/storage/secure_storage.dart';
import 'package:aifb/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:aifb/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockStorage extends Mock implements SecureStorage {}

void main() {
  late _MockRemote remote;
  late _MockStorage storage;
  late AuthRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    storage = _MockStorage();
    repo = AuthRepositoryImpl(remote: remote, storage: storage);
  });

  test('forgotPassword returns Ok with devCode', () async {
    when(() => remote.forgotPassword('a@b.com'))
        .thenAnswer((_) async => '123456');
    final result = await repo.forgotPassword(email: 'a@b.com');
    expect(result, isA<Ok<String?>>());
    expect((result as Ok<String?>).value, '123456');
  });

  test('forgotPassword returns Ok with null devCode', () async {
    when(() => remote.forgotPassword('a@b.com')).thenAnswer((_) async => null);
    final result = await repo.forgotPassword(email: 'a@b.com');
    expect((result as Ok<String?>).value, isNull);
  });

  test('resetPassword forwards all fields and returns Ok', () async {
    when(() => remote.resetPassword(
          email: any(named: 'email'),
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) async {});
    final result = await repo.resetPassword(
      email: 'a@b.com',
      code: '123456',
      newPassword: 'newpass123',
    );
    expect(result, isA<Ok<void>>());
    verify(() => remote.resetPassword(
          email: 'a@b.com',
          code: '123456',
          newPassword: 'newpass123',
        )).called(1);
  });
}
```

- [ ] **Step 2: Прогнать тест — red (не компилируется: сигнатуры ещё `void`/без email)**

Run:
```bash
cd frontend && flutter test test/features/auth/auth_repository_test.dart
```
Expected: FAIL (компиляция: `forgotPassword` возвращает `void`, `resetPassword` без `email`).

- [ ] **Step 3: Обновить data source**

В `auth_remote_data_source.dart` заменить метод `forgotPassword`:

```dart
  Future<void> forgotPassword(String email) async {
    await _dio.post<void>(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
      options: Options(extra: {'skipAuth': true}),
    );
  }
```

на:

```dart
  /// Возвращает devCode (dev-режим: код приходит в ответе, SMTP не настроен)
  /// либо null, если email не зарегистрирован.
  Future<String?> forgotPassword(String email) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
      options: Options(extra: {'skipAuth': true}),
    );
    final data = res.data?['data'];
    if (data is Map<String, dynamic>) {
      final code = data['devCode'];
      return code is String ? code : null;
    }
    return null;
  }
```

И заменить `resetPassword`:

```dart
  Future<void> resetPassword({
    required String code,
    required String newPassword,
  }) async {
    await _dio.post<void>(
      ApiEndpoints.resetPassword,
      data: {'code': code, 'newPassword': newPassword},
      options: Options(extra: {'skipAuth': true}),
    );
  }
```

на:

```dart
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _dio.post<void>(
      ApiEndpoints.resetPassword,
      data: {'email': email, 'code': code, 'newPassword': newPassword},
      options: Options(extra: {'skipAuth': true}),
    );
  }
```

- [ ] **Step 4: Обновить интерфейс репозитория**

В `auth_repository.dart` заменить:

```dart
  Future<Result<void>> forgotPassword({required String email});

  Future<Result<void>> resetPassword({
    required String code,
    required String newPassword,
  });
```

на:

```dart
  Future<Result<String?>> forgotPassword({required String email});

  Future<Result<void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
```

- [ ] **Step 5: Обновить реализацию репозитория**

В `auth_repository_impl.dart` заменить:

```dart
  @override
  Future<Result<void>> forgotPassword({required String email}) =>
      _guard(() => _remote.forgotPassword(email));

  @override
  Future<Result<void>> resetPassword({
    required String code,
    required String newPassword,
  }) =>
      _guard(() => _remote.resetPassword(code: code, newPassword: newPassword));
```

на:

```dart
  @override
  Future<Result<String?>> forgotPassword({required String email}) =>
      _guard(() => _remote.forgotPassword(email));

  @override
  Future<Result<void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) =>
      _guard(() => _remote.resetPassword(
            email: email,
            code: code,
            newPassword: newPassword,
          ));
```

- [ ] **Step 6: Прогнать тест — green**

Run:
```bash
cd frontend && flutter test test/features/auth/auth_repository_test.dart
```
Expected: PASS (3 теста).

- [ ] **Step 7: Commit**

```bash
git add frontend/lib/features/auth/data/datasources/auth_remote_data_source.dart \
        frontend/lib/features/auth/domain/repositories/auth_repository.dart \
        frontend/lib/features/auth/data/repositories/auth_repository_impl.dart \
        frontend/test/features/auth/auth_repository_test.dart
git commit -m "feat(auth-fe): data-слой восстановления пароля (devCode + email в reset)"
```

---

## Task 5: Frontend — состояние и контроллер

**Files:**
- Modify: `frontend/lib/features/auth/presentation/state/forgot_password_state.dart` (+ регенерация `.freezed.dart`)
- Modify: `frontend/lib/features/auth/presentation/controllers/forgot_password_controller.dart`
- Test: `frontend/test/features/auth/forgot_password_controller_test.dart`

- [ ] **Step 1: Расширить стейт**

Полностью заменить содержимое `forgot_password_state.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/failure.dart';

part 'forgot_password_state.freezed.dart';

enum ForgotStep { request, reset }

@freezed
class ForgotPasswordState with _$ForgotPasswordState {
  const factory ForgotPasswordState({
    @Default(ForgotStep.request) ForgotStep step,
    @Default('') String email,
    String? emailError,
    @Default(false) bool submitting,
    String? devCode,
    @Default('') String code,
    String? codeError,
    @Default('') String newPassword,
    String? newPasswordError,
    @Default(false) bool resetSubmitting,
    @Default(false) bool resetDone,
    Failure? failure,
  }) = _ForgotPasswordState;
}
```

- [ ] **Step 2: Регенерировать freezed**

Run:
```bash
cd frontend && dart run build_runner build --delete-conflicting-outputs
```
Expected: успешная генерация, обновлён `forgot_password_state.freezed.dart`.

- [ ] **Step 3: Переписать контроллер**

Полностью заменить содержимое `forgot_password_controller.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_result.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';
import '../state/forgot_password_state.dart';

class ForgotPasswordController extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordController(this._ref) : super(const ForgotPasswordState());

  final Ref _ref;

  void emailChanged(String v) =>
      state = state.copyWith(email: v, emailError: null, failure: null);

  void codeChanged(String v) =>
      state = state.copyWith(code: v, codeError: null, failure: null);

  void newPasswordChanged(String v) => state =
      state.copyWith(newPassword: v, newPasswordError: null, failure: null);

  Future<void> requestCode() async {
    final err = Validators.email(state.email);
    if (err != null) {
      state = state.copyWith(emailError: err);
      return;
    }
    state = state.copyWith(submitting: true, failure: null);
    final res = await _ref
        .read(authRepositoryProvider)
        .forgotPassword(email: state.email.trim());
    switch (res) {
      case Ok(:final value):
        state = state.copyWith(
          submitting: false,
          step: ForgotStep.reset,
          devCode: value,
        );
      case Err(:final failure):
        state = state.copyWith(submitting: false, failure: failure);
    }
  }

  Future<void> reset() async {
    final codeErr = Validators.code(state.code);
    final pwErr = Validators.password(state.newPassword);
    if (codeErr != null || pwErr != null) {
      state = state.copyWith(codeError: codeErr, newPasswordError: pwErr);
      return;
    }
    state = state.copyWith(resetSubmitting: true, failure: null);
    final res = await _ref.read(authRepositoryProvider).resetPassword(
          email: state.email.trim(),
          code: state.code.trim(),
          newPassword: state.newPassword,
        );
    switch (res) {
      case Ok():
        state = state.copyWith(resetSubmitting: false, resetDone: true);
      case Err(:final failure):
        state = state.copyWith(resetSubmitting: false, failure: failure);
    }
  }

  void backToRequest() => state =
      state.copyWith(step: ForgotStep.request, devCode: null, failure: null);
}

final forgotPasswordControllerProvider = StateNotifierProvider.autoDispose<
    ForgotPasswordController, ForgotPasswordState>(
  (ref) => ForgotPasswordController(ref),
);
```

- [ ] **Step 4: Написать тест контроллера**

`frontend/test/features/auth/forgot_password_controller_test.dart`:

```dart
import 'package:aifb/core/errors/failure.dart';
import 'package:aifb/core/network/api_result.dart';
import 'package:aifb/features/auth/domain/repositories/auth_repository.dart';
import 'package:aifb/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:aifb/features/auth/presentation/providers/auth_providers.dart';
import 'package:aifb/features/auth/presentation/state/forgot_password_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockAuthRepo();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  ForgotPasswordController ctrl() =>
      container.read(forgotPasswordControllerProvider.notifier);
  ForgotPasswordState state() =>
      container.read(forgotPasswordControllerProvider);

  test('requestCode with devCode moves to reset step', () async {
    when(() => repo.forgotPassword(email: any(named: 'email')))
        .thenAnswer((_) async => const Result.ok('123456'));
    ctrl().emailChanged('a@b.com');
    await ctrl().requestCode();
    expect(state().step, ForgotStep.reset);
    expect(state().devCode, '123456');
  });

  test('requestCode with null devCode still moves to reset step', () async {
    when(() => repo.forgotPassword(email: any(named: 'email')))
        .thenAnswer((_) async => const Result<String?>.ok(null));
    ctrl().emailChanged('a@b.com');
    await ctrl().requestCode();
    expect(state().step, ForgotStep.reset);
    expect(state().devCode, isNull);
  });

  test('requestCode with invalid email does not call repo', () async {
    ctrl().emailChanged('not-an-email');
    await ctrl().requestCode();
    expect(state().emailError, isNotNull);
    expect(state().step, ForgotStep.request);
    verifyNever(() => repo.forgotPassword(email: any(named: 'email')));
  });

  test('reset success sets resetDone', () async {
    when(() => repo.resetPassword(
          email: any(named: 'email'),
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) async => const Result<void>.ok(null));
    ctrl()
      ..emailChanged('a@b.com')
      ..codeChanged('123456')
      ..newPasswordChanged('secret123');
    await ctrl().reset();
    expect(state().resetDone, isTrue);
  });

  test('reset failure sets failure and not done', () async {
    when(() => repo.resetPassword(
          email: any(named: 'email'),
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer(
      (_) async => const Result<void>.err(Failure.validation(message: 'bad')),
    );
    ctrl()
      ..emailChanged('a@b.com')
      ..codeChanged('123456')
      ..newPasswordChanged('secret123');
    await ctrl().reset();
    expect(state().resetDone, isFalse);
    expect(state().failure, isNotNull);
  });

  test('reset with invalid code does not call repo', () async {
    ctrl()
      ..emailChanged('a@b.com')
      ..codeChanged('12')
      ..newPasswordChanged('secret123');
    await ctrl().reset();
    expect(state().codeError, isNotNull);
    verifyNever(() => repo.resetPassword(
          email: any(named: 'email'),
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        ));
  });
}
```

- [ ] **Step 5: Прогнать тест — green**

Run:
```bash
cd frontend && flutter test test/features/auth/forgot_password_controller_test.dart
```
Expected: PASS (6 тестов). Если `Result<void>.ok(null)` не компилируется — свериться с тем, как `_guard` строит `Result<void>` для `logout()` (тот же тип), и привести вызов к рабочему виду.

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/auth/presentation/state/forgot_password_state.dart \
        frontend/lib/features/auth/presentation/state/forgot_password_state.freezed.dart \
        frontend/lib/features/auth/presentation/controllers/forgot_password_controller.dart \
        frontend/test/features/auth/forgot_password_controller_test.dart
git commit -m "feat(auth-fe): контроллер восстановления пароля (два шага: код → новый пароль)"
```

---

## Task 6: Frontend — экран и маршрут

**Files:**
- Create: `frontend/lib/features/auth/presentation/pages/forgot_password_page.dart`
- Modify: `frontend/lib/app/router/app_router.dart`

- [ ] **Step 1: Создать `ForgotPasswordPage`**

```dart
import 'package:aifb/app/router/routes.dart';
import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/core/errors/failure.dart';
import 'package:aifb/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:aifb/features/auth/presentation/state/forgot_password_state.dart';
import 'package:aifb/shared/widgets/hig_button.dart';
import 'package:aifb/shared/widgets/hig_text_field.dart';
import 'package:aifb/shared/widgets/inset_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_syncEmail);
    _codeCtrl.addListener(_syncCode);
    _passwordCtrl.addListener(_syncPassword);
  }

  @override
  void dispose() {
    _emailCtrl
      ..removeListener(_syncEmail)
      ..dispose();
    _codeCtrl
      ..removeListener(_syncCode)
      ..dispose();
    _passwordCtrl
      ..removeListener(_syncPassword)
      ..dispose();
    super.dispose();
  }

  void _syncEmail() => ref
      .read(forgotPasswordControllerProvider.notifier)
      .emailChanged(_emailCtrl.text);

  void _syncCode() => ref
      .read(forgotPasswordControllerProvider.notifier)
      .codeChanged(_codeCtrl.text);

  void _syncPassword() => ref
      .read(forgotPasswordControllerProvider.notifier)
      .newPasswordChanged(_passwordCtrl.text);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final hig = HigColors.of(context);

    ref.listen<ForgotPasswordState>(forgotPasswordControllerProvider,
        (prev, next) {
      final f = next.failure;
      if (f != null && f != prev?.failure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_failureMessage(f))));
      }
      if (next.resetDone && !(prev?.resetDone ?? false)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Пароль изменён')));
        context.go(AppRoutes.login.path);
      }
    });

    return Scaffold(
      backgroundColor: hig.pageBackground,
      appBar: AppBar(
        backgroundColor: hig.pageBackground,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: () => context.go(AppRoutes.login.path)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: state.step == ForgotStep.request
                  ? _requestStep(context, state, hig)
                  : _resetStep(context, state, hig),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _requestStep(
    BuildContext context,
    ForgotPasswordState state,
    HigColors hig,
  ) =>
      [
        Text(
          'Восстановление',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Введите email — пришлём код для сброса пароля',
          style: TextStyle(color: hig.secondaryLabel),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        HigTextField(
          controller: _emailCtrl,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          errorText: state.emailError,
        ),
        const SizedBox(height: 16),
        HigButton(
          label: 'Получить код',
          loading: state.submitting,
          onPressed: state.submitting
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  ref
                      .read(forgotPasswordControllerProvider.notifier)
                      .requestCode();
                },
        ),
      ];

  List<Widget> _resetStep(
    BuildContext context,
    ForgotPasswordState state,
    HigColors hig,
  ) =>
      [
        Text(
          'Новый пароль',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (state.devCode != null)
          InsetSection(
            header: 'dev-режим',
            children: [
              InsetTile(
                title: state.devCode!,
                subtitle: 'В проде код придёт на почту',
              ),
            ],
          )
        else
          Text(
            'Если email зарегистрирован, код отправлен',
            style: TextStyle(color: hig.secondaryLabel),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),
        HigTextField(
          controller: _codeCtrl,
          label: 'Код из 6 цифр',
          keyboardType: TextInputType.number,
          errorText: state.codeError,
        ),
        const SizedBox(height: 12),
        HigTextField(
          controller: _passwordCtrl,
          label: 'Новый пароль',
          obscureText: true,
          errorText: state.newPasswordError,
        ),
        const SizedBox(height: 16),
        HigButton(
          label: 'Сбросить пароль',
          loading: state.resetSubmitting,
          onPressed: state.resetSubmitting
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  ref.read(forgotPasswordControllerProvider.notifier).reset();
                },
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => ref
              .read(forgotPasswordControllerProvider.notifier)
              .backToRequest(),
          child: const Text('Запросить код заново'),
        ),
      ];
}

String _failureMessage(Failure f) {
  return switch (f) {
    NetworkFailure(:final message) => message ?? 'Нет соединения. Попробуйте ещё раз.',
    TimeoutFailure() => 'Превышено время ожидания. Попробуйте ещё раз.',
    UnauthorizedFailure(:final message) => message ?? 'Сессия недействительна.',
    ForbiddenFailure(:final message) => message ?? 'Доступ запрещён.',
    NotFoundFailure(:final message) => message ?? 'Не найдено.',
    ConflictFailure(:final message) => message ?? 'Конфликт данных.',
    ValidationFailure(:final message) => message ?? 'Неверный или просроченный код.',
    ServerFailure(:final message) => message ?? 'Ошибка сервера. Попробуйте ещё раз.',
    UnknownFailure(:final message) => message ?? 'Что-то пошло не так.',
  };
}
```

> Проверить сигнатуру `ValidationFailure` в `core/errors/failure.dart`: фабрика — `Failure.validation({String? message, ...})`. Если `message` не nullable либо есть доп. поля — привести паттерн `switch` в соответствие (значения по умолчанию сохранить).

- [ ] **Step 2: Подключить страницу в роутер**

В `app_router.dart` добавить импорт (рядом с импортами страниц `auth`, по алфавиту):

```dart
import 'package:aifb/features/auth/presentation/pages/forgot_password_page.dart';
```

Заменить блок маршрута `forgotPassword`:

```dart
      GoRoute(
        path: AppRoutes.forgotPassword.path,
        name: AppRoutes.forgotPassword.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const _Placeholder(title: 'Forgot Password'),
        ),
      ),
```

на:

```dart
      GoRoute(
        path: AppRoutes.forgotPassword.path,
        name: AppRoutes.forgotPassword.name,
        pageBuilder: (ctx, state) => fadeThroughPage(
          key: state.pageKey,
          child: const ForgotPasswordPage(),
        ),
      ),
```

- [ ] **Step 3: Анализ и сборка**

Run:
```bash
cd frontend && flutter analyze && flutter test && flutter build web
```
Expected: analyze — без ошибок (lint-уровень `info`/`warning` допустим, как в проекте); все тесты PASS; web-сборка успешна.

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/features/auth/presentation/pages/forgot_password_page.dart \
        frontend/lib/app/router/app_router.dart
git commit -m "feat(auth-fe): экран восстановления пароля (два шага) + подключение маршрута"
```

---

## Self-Review (выполнено при написании плана)

**1. Покрытие спеки:**
- Хранилище кодов (V13 + entity + repo, одноразовость, один активный код) → Task 1 + `markAllActiveUsed`.
- `forgotPassword` (devCode для известного, null для неизвестного) → Task 2 (Steps 1,6) + тесты.
- `reset` (BCrypt-сверка, TTL, новый пароль, tokenVersion++, revokeAll, mark used) → Task 2 Step 6.
- Эндпоинты `/api/v1/auth/forgot-password|reset-password` + валидация пароля/кода → Task 2 Steps 3-7.
- Истечение кода → Task 3.
- Data-слой (devCode + email) → Task 4. Стейт/контроллер (2 шага) → Task 5. Экран + маршрут → Task 6.
- Не раскрываем существование email; неверный/просроченный код → один код `AUTH_RESET_CODE_INVALID` → Task 2.

**2. Плейсхолдеры:** не обнаружено — весь код приведён.

**3. Согласованность типов:** `forgotPassword` → `Future<Result<String?>>` (data source `Future<String?>`); `resetPassword({email,code,newPassword})` единообразно в data source / интерфейсе / impl / контроллере / тестах. `ForgotStep`, поля стейта и обращения к ним (`step`, `devCode`, `code`, `newPassword`, `resetSubmitting`, `resetDone`) согласованы между стейтом, контроллером, страницей и тестами. Код ошибки `AUTH_RESET_CODE_INVALID` единый в enum, сервисе и тестах.

## Точки сверки с фактическим кодом (для исполнителя)
- Форма поля кода ошибки в конверте (`$.error.code`) — свериться с `GlobalExceptionHandler`.
- Security-конфиг: убедиться, что `/api/v1/auth/forgot-password` и `/reset-password` публичны.
- `Result<void>.ok(null)` / `Result<void>.err(...)` — свериться с тем, как `_guard` типизирует `Result<void>` для `logout()`.
- Сигнатура `Failure.validation(...)` — при отличии поправить `switch` в `_failureMessage`.
