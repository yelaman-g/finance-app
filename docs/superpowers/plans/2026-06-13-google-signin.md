# Быстрая регистрация через Google (Android) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Дать вход «в 1–2 нажатия» через Google: backend `POST /api/v1/auth/google` (верификация Google ID-token → find-or-create → JWT-сессия) и кнопка «Войти через Google» на экране входа (Android), с dev-режимом для работы без реального Google-проекта.

**Architecture:** Верификация ID-token спрятана за интерфейсом `GoogleTokenVerifier` с двумя реализациями (`Real` поверх google-api-client / `Dev` парсит неподписанный `dev.<base64>`-токен), выбор — по `aifb.google.dev-mode` (дефолт `true`, как dev-код восстановления пароля). `AuthService.loginWithGoogle` связывает по `google_subject`, затем по email, иначе создаёт юзера без пароля и переиспользует существующий `issueSession`. Фронт: `GoogleSignInService` отдаёт idToken (в dev-режиме — собирает dev-токен, не дёргая плагин), дальше тот же поток, что у `login`.

**Tech Stack:** Java 21, Spring Boot 3.3.5, Spring Security (JWT), Spring Data JPA, Flyway, Testcontainers, MockMvc · Flutter (Dart 3), Riverpod, Dio, flutter_dotenv, flutter_svg, google_sign_in ^6.x, mocktail.

**Спека:** `docs/superpowers/specs/2026-06-13-google-signin-design.md`

> **Заметка по неймингу:** спека упоминала префикс `app.google`; в плане используем `aifb.google` — для согласованности с существующим namespace `aifb.*` (`aifb.security.*`, `aifb.verification.*`). Это единственное уточнение относительно спеки.

> **Заметка по среде:** backend-тесты используют Testcontainers (нужен Docker). Реальный Google-путь (`RealGoogleTokenVerifier` + плагин `google_sign_in`) компилируется и конфигурируется, но end-to-end не проверяется в этой среде без реального OAuth Client ID — он покрыт изоляцией за интерфейсом и включается конфигом (`GOOGLE_DEV_MODE=false`).

---

## Файловая структура

**Backend — создать:**
- `backend/src/main/java/com/aifb/platform/auth/service/google/GoogleIdentity.java` — DTO результата верификации.
- `backend/src/main/java/com/aifb/platform/auth/service/google/GoogleTokenVerifier.java` — интерфейс.
- `backend/src/main/java/com/aifb/platform/auth/service/google/DevGoogleTokenVerifier.java` — dev-реализация.
- `backend/src/main/java/com/aifb/platform/auth/service/google/RealGoogleTokenVerifier.java` — prod-реализация.
- `backend/src/main/java/com/aifb/platform/config/GoogleAuthConfig.java` — выбор бина по конфигу.
- `backend/src/main/java/com/aifb/platform/auth/api/dto/GoogleAuthRequest.java` — тело запроса.
- `backend/src/main/resources/db/migration/V14__google_auth.sql` — миграция.
- `backend/src/test/java/com/aifb/platform/auth/service/google/DevGoogleTokenVerifierTest.java` — unit-тест dev-верификатора.
- `backend/src/test/java/com/aifb/platform/auth/GoogleAuthApiIT.java` — интеграционный тест эндпоинта.

**Backend — изменить:**
- `backend/src/main/java/com/aifb/platform/common/exception/ErrorCode.java` — новый код.
- `backend/src/main/java/com/aifb/platform/auth/domain/User.java` — nullable пароль, поле `googleSubject`, фабрика, `linkGoogle`.
- `backend/src/main/java/com/aifb/platform/auth/repository/UserRepository.java` — `findByGoogleSubject`.
- `backend/src/main/java/com/aifb/platform/auth/service/AuthService.java` — `loginWithGoogle` + фикс `login`.
- `backend/src/main/java/com/aifb/platform/auth/api/AuthController.java` — эндпоинт `/google`.
- `backend/src/main/java/com/aifb/platform/config/SecurityConfig.java` — публичный путь.
- `backend/build.gradle` — зависимость google-api-client.
- `backend/src/main/resources/application.yml` — `aifb.google.*`.

**Frontend — создать:**
- `frontend/lib/features/auth/data/google_auth_config.dart` — чтение env.
- `frontend/lib/features/auth/data/google_sign_in_service.dart` — получение idToken (dev/real).
- `frontend/assets/google_logo.svg` — лого Google.
- `frontend/test/features/auth/google_sign_in_service_test.dart` — unit-тест dev-токена.
- `frontend/test/features/auth/login_page_test.dart` — widget-тест экрана входа.

**Frontend — изменить:**
- `frontend/pubspec.yaml` — зависимость + assets.
- `frontend/.env` — `GOOGLE_CLIENT_ID`, `GOOGLE_DEV_MODE`.
- `frontend/lib/core/network/api_endpoints.dart` — путь `/auth/google`.
- `frontend/lib/features/auth/data/datasources/auth_remote_data_source.dart` — `signInWithGoogle`.
- `frontend/lib/features/auth/domain/repositories/auth_repository.dart` — метод в интерфейсе.
- `frontend/lib/features/auth/data/repositories/auth_repository_impl.dart` — реализация.
- `frontend/lib/features/auth/presentation/providers/auth_providers.dart` — провайдер сервиса.
- `frontend/lib/features/auth/presentation/controllers/auth_controller.dart` — `signInWithGoogle`.
- `frontend/lib/features/auth/presentation/controllers/login_controller.dart` — `signInWithGoogle`.
- `frontend/lib/features/auth/presentation/pages/login_page.dart` — рестайл + кнопка Google.
- `frontend/test/features/auth/auth_repository_test.dart` — тест нового метода.
- `docs/DEPLOYMENT.md` — env-переменные Google.

---

## Task B1: Инфраструктура верификации Google-токена

**Files:**
- Create: `backend/src/main/java/com/aifb/platform/auth/service/google/GoogleIdentity.java`
- Create: `backend/src/main/java/com/aifb/platform/auth/service/google/GoogleTokenVerifier.java`
- Create: `backend/src/main/java/com/aifb/platform/auth/service/google/DevGoogleTokenVerifier.java`
- Create: `backend/src/main/java/com/aifb/platform/auth/service/google/RealGoogleTokenVerifier.java`
- Create: `backend/src/main/java/com/aifb/platform/config/GoogleAuthConfig.java`
- Modify: `backend/src/main/java/com/aifb/platform/common/exception/ErrorCode.java`
- Modify: `backend/build.gradle`
- Modify: `backend/src/main/resources/application.yml`
- Test: `backend/src/test/java/com/aifb/platform/auth/service/google/DevGoogleTokenVerifierTest.java`

- [ ] **Step 1: Add error code**

В `ErrorCode.java` заменить последнюю константу (она оканчивается на `;`), добавив новую:

```java
    AUTH_RESET_CODE_INVALID("AUTH_RESET_CODE_INVALID", HttpStatus.BAD_REQUEST),
    AUTH_GOOGLE_TOKEN_INVALID("AUTH_GOOGLE_TOKEN_INVALID", HttpStatus.UNAUTHORIZED);
```

- [ ] **Step 2: Create GoogleIdentity + interface**

`GoogleIdentity.java`:
```java
package com.aifb.platform.auth.service.google;

public record GoogleIdentity(
        String subject,
        String email,
        boolean emailVerified,
        String fullName,
        String pictureUrl) {
}
```

`GoogleTokenVerifier.java`:
```java
package com.aifb.platform.auth.service.google;

public interface GoogleTokenVerifier {
    GoogleIdentity verify(String idToken);
}
```

- [ ] **Step 3: Write the failing test for DevGoogleTokenVerifier**

`DevGoogleTokenVerifierTest.java`:
```java
package com.aifb.platform.auth.service.google;

import com.aifb.platform.common.exception.UnauthorizedException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.util.Base64;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class DevGoogleTokenVerifierTest {

    private final DevGoogleTokenVerifier verifier =
            new DevGoogleTokenVerifier(new ObjectMapper());

    private String token(String json) {
        return "dev." + Base64.getUrlEncoder().withoutPadding()
                .encodeToString(json.getBytes(StandardCharsets.UTF_8));
    }

    @Test
    void parsesValidDevToken() {
        GoogleIdentity id = verifier.verify(token(
                "{\"sub\":\"g-1\",\"email\":\"a@gmail.com\",\"name\":\"Alice\","
                        + "\"picture\":\"http://x/p.png\",\"email_verified\":true}"));
        assertThat(id.subject()).isEqualTo("g-1");
        assertThat(id.email()).isEqualTo("a@gmail.com");
        assertThat(id.fullName()).isEqualTo("Alice");
        assertThat(id.pictureUrl()).isEqualTo("http://x/p.png");
        assertThat(id.emailVerified()).isTrue();
    }

    @Test
    void emailVerifiedDefaultsTrueWhenMissing() {
        GoogleIdentity id = verifier.verify(token(
                "{\"sub\":\"g-2\",\"email\":\"b@gmail.com\"}"));
        assertThat(id.emailVerified()).isTrue();
    }

    @Test
    void rejectsTokenWithoutPrefix() {
        assertThatThrownBy(() -> verifier.verify("not-a-dev-token"))
                .isInstanceOf(UnauthorizedException.class);
    }

    @Test
    void rejectsMalformedPayload() {
        assertThatThrownBy(() -> verifier.verify("dev.@@@notbase64@@@"))
                .isInstanceOf(UnauthorizedException.class);
    }

    @Test
    void rejectsMissingSubOrEmail() {
        assertThatThrownBy(() -> verifier.verify(token("{\"email\":\"c@gmail.com\"}")))
                .isInstanceOf(UnauthorizedException.class);
    }
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `cd backend && ./gradlew test --tests "com.aifb.platform.auth.service.google.DevGoogleTokenVerifierTest"`
Expected: FAIL — `DevGoogleTokenVerifier` does not exist (compilation error).

- [ ] **Step 5: Implement DevGoogleTokenVerifier**

`DevGoogleTokenVerifier.java`:
```java
package com.aifb.platform.auth.service.google;

import com.aifb.platform.common.exception.ErrorCode;
import com.aifb.platform.common.exception.UnauthorizedException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.nio.charset.StandardCharsets;
import java.util.Base64;

/**
 * Принимает неподписанный токен вида {@code dev.<base64url(JSON)>} без обращения
 * к сети. Аналог dev-кода восстановления пароля: удобно для тестов и демо без
 * реального Google-проекта. ДОЛЖЕН быть выключен в продакшне (GOOGLE_DEV_MODE=false).
 */
public class DevGoogleTokenVerifier implements GoogleTokenVerifier {

    private static final String PREFIX = "dev.";
    private final ObjectMapper objectMapper;

    public DevGoogleTokenVerifier(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    public GoogleIdentity verify(String idToken) {
        if (idToken == null || !idToken.startsWith(PREFIX)) {
            throw invalid();
        }
        try {
            byte[] decoded = Base64.getUrlDecoder().decode(idToken.substring(PREFIX.length()));
            JsonNode node = objectMapper.readTree(new String(decoded, StandardCharsets.UTF_8));
            String sub = text(node, "sub");
            String email = text(node, "email");
            if (sub == null || email == null) {
                throw invalid();
            }
            boolean emailVerified = !node.has("email_verified")
                    || node.get("email_verified").asBoolean(true);
            return new GoogleIdentity(sub, email, emailVerified, text(node, "name"), text(node, "picture"));
        } catch (UnauthorizedException e) {
            throw e;
        } catch (Exception e) {
            throw invalid();
        }
    }

    private static String text(JsonNode node, String field) {
        JsonNode v = node.get(field);
        return v == null || v.isNull() ? null : v.asText();
    }

    private static UnauthorizedException invalid() {
        return new UnauthorizedException(ErrorCode.AUTH_GOOGLE_TOKEN_INVALID, "Invalid Google token");
    }
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `cd backend && ./gradlew test --tests "com.aifb.platform.auth.service.google.DevGoogleTokenVerifierTest"`
Expected: PASS (5 tests).

- [ ] **Step 7: Add google-api-client dependency**

В `backend/build.gradle` в блок `dependencies { ... }` (после строки springdoc, до блока `testImplementation`) добавить:
```groovy
    implementation 'com.google.api-client:google-api-client:2.7.0'
```

- [ ] **Step 8: Implement RealGoogleTokenVerifier**

`RealGoogleTokenVerifier.java`:
```java
package com.aifb.platform.auth.service.google;

import com.aifb.platform.common.exception.ErrorCode;
import com.aifb.platform.common.exception.UnauthorizedException;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;

import java.util.Collections;

/**
 * Верифицирует подпись/aud/exp Google ID-token через библиотеку google-api-client.
 * Активен при aifb.google.dev-mode=false; audience = aifb.google.client-id.
 */
public class RealGoogleTokenVerifier implements GoogleTokenVerifier {

    private final GoogleIdTokenVerifier verifier;

    public RealGoogleTokenVerifier(String clientId) {
        try {
            this.verifier = new GoogleIdTokenVerifier.Builder(
                    GoogleNetHttpTransport.newTrustedTransport(), GsonFactory.getDefaultInstance())
                    .setAudience(Collections.singletonList(clientId))
                    .build();
        } catch (Exception e) {
            throw new IllegalStateException("Failed to initialize Google token verifier", e);
        }
    }

    @Override
    public GoogleIdentity verify(String idToken) {
        try {
            GoogleIdToken token = verifier.verify(idToken);
            if (token == null) {
                throw invalid();
            }
            GoogleIdToken.Payload p = token.getPayload();
            return new GoogleIdentity(
                    p.getSubject(),
                    p.getEmail(),
                    Boolean.TRUE.equals(p.getEmailVerified()),
                    (String) p.get("name"),
                    (String) p.get("picture"));
        } catch (UnauthorizedException e) {
            throw e;
        } catch (Exception e) {
            throw invalid();
        }
    }

    private static UnauthorizedException invalid() {
        return new UnauthorizedException(ErrorCode.AUTH_GOOGLE_TOKEN_INVALID, "Invalid Google token");
    }
}
```

- [ ] **Step 9: Implement GoogleAuthConfig (bean selection)**

`GoogleAuthConfig.java`:
```java
package com.aifb.platform.config;

import com.aifb.platform.auth.service.google.DevGoogleTokenVerifier;
import com.aifb.platform.auth.service.google.GoogleTokenVerifier;
import com.aifb.platform.auth.service.google.RealGoogleTokenVerifier;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GoogleAuthConfig {

    @Bean
    @ConditionalOnProperty(prefix = "aifb.google", name = "dev-mode", havingValue = "true", matchIfMissing = true)
    public GoogleTokenVerifier devGoogleTokenVerifier(ObjectMapper objectMapper) {
        return new DevGoogleTokenVerifier(objectMapper);
    }

    @Bean
    @ConditionalOnProperty(prefix = "aifb.google", name = "dev-mode", havingValue = "false")
    public GoogleTokenVerifier realGoogleTokenVerifier(@Value("${aifb.google.client-id:}") String clientId) {
        return new RealGoogleTokenVerifier(clientId);
    }
}
```

- [ ] **Step 10: Add config to application.yml**

В `application.yml` в блок `aifb:` (после блока `verification:`) добавить:
```yaml
  google:
    client-id: ${GOOGLE_CLIENT_ID:}
    dev-mode: ${GOOGLE_DEV_MODE:true}
```

- [ ] **Step 11: Run unit test + compile**

Run: `cd backend && ./gradlew compileJava test --tests "com.aifb.platform.auth.service.google.DevGoogleTokenVerifierTest"`
Expected: BUILD SUCCESSFUL, тест зелёный, новая зависимость скачана.

- [ ] **Step 12: Commit**

```bash
git add backend/src/main/java/com/aifb/platform/auth/service/google backend/src/main/java/com/aifb/platform/config/GoogleAuthConfig.java backend/src/main/java/com/aifb/platform/common/exception/ErrorCode.java backend/build.gradle backend/src/main/resources/application.yml backend/src/test/java/com/aifb/platform/auth/service/google/DevGoogleTokenVerifierTest.java
git commit -m "feat(auth): инфраструктура верификации Google ID-token (dev/real за интерфейсом)"
```

---

## Task B2: Миграция БД + сущность User

**Files:**
- Create: `backend/src/main/resources/db/migration/V14__google_auth.sql`
- Modify: `backend/src/main/java/com/aifb/platform/auth/domain/User.java`
- Modify: `backend/src/main/java/com/aifb/platform/auth/repository/UserRepository.java`

- [ ] **Step 1: Create migration V14**

`V14__google_auth.sql`:
```sql
-- Google-аккаунты не имеют локального пароля.
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;

-- Стабильный идентификатор Google-личности (sub из ID-token).
ALTER TABLE users ADD COLUMN google_subject VARCHAR(255);
ALTER TABLE users ADD CONSTRAINT uq_users_google_subject UNIQUE (google_subject);
```

- [ ] **Step 2: Update User entity — nullable password + google_subject field**

В `User.java` заменить аннотацию поля пароля (убрать `nullable = false`):
```java
    @Column(name = "password_hash", length = 100)
    private String passwordHash;
```

После поля `enabled` (перед `tokenVersion`) добавить поле:
```java
    @Column(name = "google_subject", unique = true, length = 255)
    private String googleSubject;
```

- [ ] **Step 3: Add getter, factory and linkGoogle to User**

В `User.java` добавить геттер рядом с остальными:
```java
    public String getGoogleSubject() { return googleSubject; }
```

Добавить статическую фабрику (после публичного конструктора):
```java
    public static User googleUser(String email, String fullName, String googleSubject, String avatarUrl) {
        User user = new User();
        user.id = UUID.randomUUID();
        user.email = email;
        user.fullName = fullName;
        user.passwordHash = null;
        user.googleSubject = googleSubject;
        user.emailVerified = true;
        user.avatarUrl = avatarUrl;
        user.roles = new HashSet<>(Set.of(Role.USER));
        return user;
    }
```

Добавить метод связывания (рядом с `changePassword`):
```java
    public void linkGoogle(String googleSubject, String pictureUrl) {
        this.googleSubject = googleSubject;
        this.emailVerified = true;
        if (this.avatarUrl == null || this.avatarUrl.isBlank()) {
            this.avatarUrl = pictureUrl;
        }
    }
```

(`Role` уже импортирован? Нет — добавить импорт `import com.aifb.platform.auth.domain.Role;` НЕ нужен, `Role` в том же пакете. `HashSet`, `Set`, `UUID` уже импортированы.)

- [ ] **Step 4: Add repository finder**

В `UserRepository.java` добавить метод в интерфейс:
```java
    Optional<User> findByGoogleSubject(String googleSubject);
```

- [ ] **Step 5: Verify schema/entity alignment (Flyway validate boots context)**

Run: `cd backend && ./gradlew test --tests "com.aifb.platform.SmokeContextIT"`
Expected: PASS — контекст поднимается, Flyway применяет V14, JPA `ddl-auto: validate` подтверждает соответствие сущности схеме (требует Docker для Testcontainers).

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/resources/db/migration/V14__google_auth.sql backend/src/main/java/com/aifb/platform/auth/domain/User.java backend/src/main/java/com/aifb/platform/auth/repository/UserRepository.java
git commit -m "feat(auth): миграция V14 (nullable пароль + google_subject) и поддержка в User"
```

---

## Task B3: Падающий интеграционный тест эндпоинта /auth/google

**Files:**
- Create: `backend/src/test/java/com/aifb/platform/auth/GoogleAuthApiIT.java`

- [ ] **Step 1: Write the failing integration test**

`GoogleAuthApiIT.java`:
```java
package com.aifb.platform.auth;

import com.aifb.platform.support.AbstractIntegrationTest;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MvcResult;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class GoogleAuthApiIT extends AbstractIntegrationTest {

    @Autowired
    ObjectMapper objectMapper;

    private String uniqueEmail() {
        return "g-" + UUID.randomUUID() + "@example.com";
    }

    private String devToken(String sub, String email, String name, boolean emailVerified) {
        String json = "{\"sub\":\"" + sub + "\",\"email\":\"" + email + "\",\"name\":\"" + name
                + "\",\"email_verified\":" + emailVerified + "}";
        return "dev." + Base64.getUrlEncoder().withoutPadding()
                .encodeToString(json.getBytes(StandardCharsets.UTF_8));
    }

    private MvcResult google(String idToken, int expectedStatus) throws Exception {
        return mockMvc.perform(post("/api/v1/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"idToken\":\"" + idToken + "\"}"))
                .andExpect(status().is(expectedStatus))
                .andReturn();
    }

    private String userId(MvcResult result) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString())
                .path("data").path("user").path("id").asText();
    }

    @Test
    void newUserIsCreatedAndSessionIssued() throws Exception {
        String email = uniqueEmail();
        MvcResult result = google(devToken("sub-" + email, email, "New User", true), 200);

        assertThat(objectMapper.readTree(result.getResponse().getContentAsString())
                .path("data").path("tokens").path("accessToken").asText()).isNotBlank();
        mockMvc.perform(post("/api/v1/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"idToken\":\"" + devToken("sub-" + email, email, "New User", true) + "\"}"))
                .andExpect(jsonPath("$.data.user.email").value(email))
                .andExpect(jsonPath("$.data.user.emailVerified").value(true));
    }

    @Test
    void sameSubjectReturnsSameUser() throws Exception {
        String email = uniqueEmail();
        String token = devToken("sub-stable", email, "Stable", true);
        String id1 = userId(google(token, 200));
        String id2 = userId(google(token, 200));
        assertThat(id2).isEqualTo(id1);
    }

    @Test
    void existingEmailAccountIsLinked() throws Exception {
        String email = uniqueEmail();
        // классическая регистрация email+пароль
        MvcResult reg = mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"fullName\":\"Local User\",\"email\":\"" + email
                                + "\",\"password\":\"password1\"}"))
                .andExpect(status().isCreated())
                .andReturn();
        String regId = userId(reg);

        // вход через Google с тем же email связывается с этим аккаунтом
        String googleId = userId(google(devToken("sub-link", email, "Local User", true), 200));
        assertThat(googleId).isEqualTo(regId);
    }

    @Test
    void invalidTokenIsRejected() throws Exception {
        mockMvc.perform(post("/api/v1/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"idToken\":\"garbage-token\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error.code").value("AUTH_GOOGLE_TOKEN_INVALID"));
    }

    @Test
    void unverifiedEmailIsRejected() throws Exception {
        mockMvc.perform(post("/api/v1/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"idToken\":\"" + devToken("sub-x", uniqueEmail(), "X", false) + "\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error.code").value("AUTH_GOOGLE_TOKEN_INVALID"));
    }

    @Test
    void passwordLoginRejectedForGoogleOnlyAccount() throws Exception {
        String email = uniqueEmail();
        google(devToken("sub-nopass", email, "No Pass", true), 200);

        // у Google-аккаунта нет пароля → вход email+пароль = 401 (не 500/NPE)
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"whatever1\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error.code").value("AUTH_INVALID_CREDENTIALS"));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && ./gradlew test --tests "com.aifb.platform.auth.GoogleAuthApiIT"`
Expected: FAIL — эндпоинт `/api/v1/auth/google` ещё не существует (404/401 от Security вместо ожидаемых статусов).

- [ ] **Step 3: Commit the failing test**

```bash
git add backend/src/test/java/com/aifb/platform/auth/GoogleAuthApiIT.java
git commit -m "test(auth): интеграционный тест /auth/google (падающий)"
```

---

## Task B4: Реализация эндпоинта и сервиса /auth/google

**Files:**
- Create: `backend/src/main/java/com/aifb/platform/auth/api/dto/GoogleAuthRequest.java`
- Modify: `backend/src/main/java/com/aifb/platform/auth/service/AuthService.java`
- Modify: `backend/src/main/java/com/aifb/platform/auth/api/AuthController.java`
- Modify: `backend/src/main/java/com/aifb/platform/config/SecurityConfig.java`

- [ ] **Step 1: Create request DTO**

`GoogleAuthRequest.java`:
```java
package com.aifb.platform.auth.api.dto;

import jakarta.validation.constraints.NotBlank;

public record GoogleAuthRequest(
        @NotBlank(message = "idToken is required")
        String idToken) {
}
```

- [ ] **Step 2: Inject verifier and add loginWithGoogle to AuthService; fix login**

В `AuthService.java` добавить импорты:
```java
import com.aifb.platform.auth.service.google.GoogleIdentity;
import com.aifb.platform.auth.service.google.GoogleTokenVerifier;
```

Добавить поле и расширить конструктор:
```java
    private final GoogleTokenVerifier googleTokenVerifier;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService,
                       RefreshTokenService refreshTokenService,
                       GoogleTokenVerifier googleTokenVerifier) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.refreshTokenService = refreshTokenService;
        this.googleTokenVerifier = googleTokenVerifier;
    }
```

В методе `login(...)` заменить проверку пароля (защита от null-пароля у Google-аккаунтов):
```java
        if (user.getPasswordHash() == null
                || !passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw invalidCredentials();
        }
```

Добавить новый метод (рядом с `login`):
```java
    @Transactional
    public AuthResponse loginWithGoogle(String idToken) {
        GoogleIdentity identity = googleTokenVerifier.verify(idToken);
        if (!identity.emailVerified()) {
            throw new UnauthorizedException(
                    ErrorCode.AUTH_GOOGLE_TOKEN_INVALID, "Google email is not verified");
        }
        String email = normalizeEmail(identity.email());
        User user = userRepository.findByGoogleSubject(identity.subject())
                .orElseGet(() -> userRepository.findByEmailIgnoreCase(email)
                        .map(existing -> {
                            existing.linkGoogle(identity.subject(), identity.pictureUrl());
                            return existing;
                        })
                        .orElseGet(() -> userRepository.save(User.googleUser(
                                email,
                                resolveName(identity, email),
                                identity.subject(),
                                identity.pictureUrl()))));
        if (!user.isEnabled()) {
            throw new UnauthorizedException(ErrorCode.AUTH_USER_BLOCKED, "User account is blocked");
        }
        user.markLoggedIn();
        return issueSession(user);
    }

    private static String resolveName(GoogleIdentity identity, String email) {
        String name = identity.fullName();
        if (name != null && !name.isBlank()) {
            return name.trim();
        }
        int at = email.indexOf('@');
        return at > 0 ? email.substring(0, at) : email;
    }
```

- [ ] **Step 3: Add controller endpoint**

В `AuthController.java` добавить импорт `import com.aifb.platform.auth.api.dto.GoogleAuthRequest;` и метод (после `login`):
```java
    @PostMapping("/google")
    public ApiResponse<AuthResponse> google(@Valid @RequestBody GoogleAuthRequest request) {
        return ApiResponse.ok(authService.loginWithGoogle(request.idToken()));
    }
```

- [ ] **Step 4: Add public endpoint in SecurityConfig**

В `SecurityConfig.java` в массив `PUBLIC_ENDPOINTS` добавить строку после `"/api/v1/auth/login",`:
```java
            "/api/v1/auth/google",
```

- [ ] **Step 5: Run the integration test to verify it passes**

Run: `cd backend && ./gradlew test --tests "com.aifb.platform.auth.GoogleAuthApiIT"`
Expected: PASS (6 tests).

- [ ] **Step 6: Run the full backend suite (no regressions)**

Run: `cd backend && ./gradlew test`
Expected: BUILD SUCCESSFUL — все прежние тесты + новые зелёные.

- [ ] **Step 7: Commit**

```bash
git add backend/src/main/java/com/aifb/platform/auth/api/dto/GoogleAuthRequest.java backend/src/main/java/com/aifb/platform/auth/service/AuthService.java backend/src/main/java/com/aifb/platform/auth/api/AuthController.java backend/src/main/java/com/aifb/platform/config/SecurityConfig.java
git commit -m "feat(auth): эндпоинт /auth/google (find-or-create + сессия) + фикс login для аккаунтов без пароля"
```

---

## Task F1: Frontend-конфиг, зависимость, ассеты

**Files:**
- Modify: `frontend/pubspec.yaml`
- Modify: `frontend/.env`
- Create: `frontend/assets/google_logo.svg`
- Create: `frontend/lib/features/auth/data/google_auth_config.dart`

- [ ] **Step 1: Add dependency and assets to pubspec**

В `frontend/pubspec.yaml` в блок `dependencies:` (рядом с другими, например после `flutter_svg`) добавить:
```yaml
  google_sign_in: ^6.2.1
```

В блок `flutter:` (после `uses-material-design: true`, перед `fonts:`) добавить секцию `assets:`:
```yaml
  assets:
    - .env
    - assets/google_logo.svg
```

- [ ] **Step 2: Add Google env vars**

В конец `frontend/.env` добавить:
```
# Google Sign-In. Dev-режим (true) не требует реального Google-проекта.
# Для прода: GOOGLE_DEV_MODE=false и заполнить GOOGLE_CLIENT_ID (web/server OAuth client).
GOOGLE_DEV_MODE=true
GOOGLE_CLIENT_ID=
```

- [ ] **Step 3: Create Google logo SVG**

`frontend/assets/google_logo.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48">
  <path fill="#FFC107" d="M43.611 20.083H42V20H24v8h11.303c-1.649 4.657-6.08 8-11.303 8-6.627 0-12-5.373-12-12s5.373-12 12-12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 12.955 4 4 12.955 4 24s8.955 20 20 20 20-8.955 20-20c0-1.341-.138-2.65-.389-3.917z"/>
  <path fill="#FF3D00" d="M6.306 14.691l6.571 4.819C14.655 15.108 18.961 12 24 12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 16.318 4 9.656 8.337 6.306 14.691z"/>
  <path fill="#4CAF50" d="M24 44c5.166 0 9.86-1.977 13.409-5.192l-6.19-5.238C29.211 35.091 26.715 36 24 36c-5.202 0-9.619-3.317-11.283-7.946l-6.522 5.025C9.505 39.556 16.227 44 24 44z"/>
  <path fill="#1976D2" d="M43.611 20.083H42V20H24v8h11.303c-.792 2.237-2.231 4.166-4.087 5.571l6.19 5.238C36.971 39.205 44 34 44 24c0-1.341-.138-2.65-.389-3.917z"/>
</svg>
```

- [ ] **Step 4: Create GoogleAuthConfig**

`frontend/lib/features/auth/data/google_auth_config.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Конфиг Google Sign-In, читаемый из .env. Безопасные дефолты: если dotenv
/// не инициализирован (например, в тестах) — dev-режим включён, clientId пуст.
class GoogleAuthConfig {
  GoogleAuthConfig._();

  static String? get clientId {
    final v = dotenv.isInitialized ? dotenv.env['GOOGLE_CLIENT_ID'] : null;
    return (v == null || v.isEmpty) ? null : v;
  }

  /// true, если явно не задано GOOGLE_DEV_MODE=false.
  static bool get devMode {
    final v = dotenv.isInitialized ? dotenv.env['GOOGLE_DEV_MODE'] : null;
    return v == null ? true : v.toLowerCase() != 'false';
  }
}
```

- [ ] **Step 5: Fetch dependency**

Run: `cd frontend && flutter pub get`
Expected: `google_sign_in` разрешён, успешно.

- [ ] **Step 6: Commit**

```bash
git add frontend/pubspec.yaml frontend/pubspec.lock frontend/.env frontend/assets/google_logo.svg frontend/lib/features/auth/data/google_auth_config.dart
git commit -m "feat(auth-fe): зависимость google_sign_in, ассеты, GoogleAuthConfig (.env)"
```

---

## Task F2: GoogleSignInService (получение idToken)

**Files:**
- Create: `frontend/lib/features/auth/data/google_sign_in_service.dart`
- Test: `frontend/test/features/auth/google_sign_in_service_test.dart`

- [ ] **Step 1: Write the failing test**

`frontend/test/features/auth/google_sign_in_service_test.dart`:
```dart
import 'dart:convert';

import 'package:aifb/features/auth/data/google_sign_in_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('в dev-режиме возвращает корректный dev-токен', () async {
    // dotenv не инициализирован в тестах → GoogleAuthConfig.devMode == true
    final service = GoogleSignInService();
    final token = await service.obtainIdToken();

    expect(token, isNotNull);
    expect(token, startsWith('dev.'));

    final payload = token!.substring('dev.'.length);
    // base64Url без паддинга → дополняем для декодирования
    final normalized = base64Url.normalize(payload);
    final json =
        jsonDecode(utf8.decode(base64Url.decode(normalized))) as Map<String, dynamic>;
    expect(json['email'], isA<String>());
    expect(json['sub'], isA<String>());
    expect(json['email_verified'], true);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/auth/google_sign_in_service_test.dart`
Expected: FAIL — `google_sign_in_service.dart` не существует (compile error).

- [ ] **Step 3: Implement GoogleSignInService**

`frontend/lib/features/auth/data/google_sign_in_service.dart`:
```dart
import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';

import 'google_auth_config.dart';

class GoogleSignInException implements Exception {
  GoogleSignInException(this.message);
  final String message;
  @override
  String toString() => 'GoogleSignInException: $message';
}

/// Возвращает Google ID-token для отправки на backend.
/// В dev-режиме собирает неподписанный `dev.<base64url>`-токен и НЕ обращается к
/// плагину (на эмуляторе без OAuth-client плагин упал бы). В prod-режиме
/// использует google_sign_in с serverClientId = GOOGLE_CLIENT_ID.
class GoogleSignInService {
  GoogleSignInService({GoogleSignIn? googleSignIn}) : _injected = googleSignIn;

  final GoogleSignIn? _injected;

  /// Возвращает idToken, либо null если пользователь отменил вход.
  Future<String?> obtainIdToken() async {
    if (GoogleAuthConfig.devMode) {
      return _devToken('demo@gmail.com', 'Demo Google User');
    }
    final signIn =
        _injected ?? GoogleSignIn(serverClientId: GoogleAuthConfig.clientId);
    final account = await signIn.signIn();
    if (account == null) {
      return null; // отмена пользователем
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw GoogleSignInException('Google не вернул ID-token');
    }
    return idToken;
  }

  static String _devToken(String email, String name) {
    final json = jsonEncode(<String, dynamic>{
      'sub': 'dev-$email',
      'email': email,
      'name': name,
      'email_verified': true,
    });
    final payload =
        base64Url.encode(utf8.encode(json)).replaceAll('=', '');
    return 'dev.$payload';
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/auth/google_sign_in_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/auth/data/google_sign_in_service.dart frontend/test/features/auth/google_sign_in_service_test.dart
git commit -m "feat(auth-fe): GoogleSignInService с dev-токеном и реальным путём"
```

---

## Task F3: Data/repo/controller — поток signInWithGoogle

**Files:**
- Modify: `frontend/lib/core/network/api_endpoints.dart`
- Modify: `frontend/lib/features/auth/data/datasources/auth_remote_data_source.dart`
- Modify: `frontend/lib/features/auth/domain/repositories/auth_repository.dart`
- Modify: `frontend/lib/features/auth/data/repositories/auth_repository_impl.dart`
- Modify: `frontend/lib/features/auth/presentation/providers/auth_providers.dart`
- Modify: `frontend/lib/features/auth/presentation/controllers/auth_controller.dart`
- Modify: `frontend/lib/features/auth/presentation/controllers/login_controller.dart`
- Test: `frontend/test/features/auth/auth_repository_test.dart`

- [ ] **Step 1: Write the failing repository test**

В `frontend/test/features/auth/auth_repository_test.dart` добавить импорты вверху:
```dart
import 'package:aifb/features/auth/data/dto/auth_dtos.dart';
```
И добавить тест внутри `main()`:
```dart
  test('signInWithGoogle сохраняет токены и возвращает Ok', () async {
    const dto = AuthSessionDto(
      user: UserDto(
        id: 'u1',
        email: 'g@gmail.com',
        fullName: 'G User',
        emailVerified: true,
      ),
      tokens: AuthTokensDto(accessToken: 'acc', refreshToken: 'ref'),
    );
    when(() => remote.signInWithGoogle('tok')).thenAnswer((_) async => dto);
    when(() => storage.saveTokens(
          access: any(named: 'access'),
          refresh: any(named: 'refresh'),
        )).thenAnswer((_) async {});

    final result = await repo.signInWithGoogle(idToken: 'tok');

    expect(result, isA<Ok<AuthSession>>());
    verify(() => storage.saveTokens(access: 'acc', refresh: 'ref')).called(1);
  });
```
Добавить импорт домена для `AuthSession` (вверху файла):
```dart
import 'package:aifb/features/auth/domain/entities/auth_session.dart';
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/auth/auth_repository_test.dart`
Expected: FAIL — `signInWithGoogle` отсутствует в `AuthRemoteDataSource`/`AuthRepository` (compile error).

- [ ] **Step 3: Add endpoint constant**

В `frontend/lib/core/network/api_endpoints.dart` в секцию `// Auth` добавить:
```dart
  static const String googleSignIn = '/auth/google';
```

- [ ] **Step 4: Add datasource method**

В `frontend/lib/features/auth/data/datasources/auth_remote_data_source.dart` добавить метод (после `register`):
```dart
  Future<AuthSessionDto> signInWithGoogle(String idToken) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.googleSignIn,
      data: {'idToken': idToken},
      options: Options(extra: {'skipAuth': true}),
    );
    return AuthSessionDto.fromJson(_unwrap(res.data));
  }
```

- [ ] **Step 5: Add to repository interface + impl**

В `frontend/lib/features/auth/domain/repositories/auth_repository.dart` добавить в интерфейс (после `register`):
```dart
  Future<Result<AuthSession>> signInWithGoogle({required String idToken});
```

В `frontend/lib/features/auth/data/repositories/auth_repository_impl.dart` добавить реализацию (после `register`):
```dart
  @override
  Future<Result<AuthSession>> signInWithGoogle({required String idToken}) =>
      _guard(() async {
        final dto = await _remote.signInWithGoogle(idToken);
        final session = dto.toDomain();
        await _storage.saveTokens(
          access: session.tokens.accessToken,
          refresh: session.tokens.refreshToken,
        );
        return session;
      });
```

- [ ] **Step 6: Run repository test to verify it passes**

Run: `cd frontend && flutter test test/features/auth/auth_repository_test.dart`
Expected: PASS.

- [ ] **Step 7: Add provider for GoogleSignInService**

В `frontend/lib/features/auth/presentation/providers/auth_providers.dart` добавить импорт и провайдер:
```dart
import '../../data/google_sign_in_service.dart';
```
```dart
final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});
```

- [ ] **Step 8: Add signInWithGoogle to AuthController**

В `frontend/lib/features/auth/presentation/controllers/auth_controller.dart` добавить импорты:
```dart
import '../../../../core/errors/failure.dart';
import '../providers/auth_providers.dart';
```
(если `auth_providers.dart` уже импортирован — не дублировать.)

Добавить метод (после `register`):
```dart
  Future<Result<void>> signInWithGoogle() async {
    final String? idToken;
    try {
      idToken = await _ref.read(googleSignInServiceProvider).obtainIdToken();
    } catch (_) {
      const failure = UnknownFailure(message: 'Не удалось войти через Google');
      state = const AuthState.unauthenticated(lastFailure: failure);
      return const Result.err(failure);
    }
    if (idToken == null) {
      return const Result.ok(null); // отмена — состояние не меняем
    }
    final res = await _repo.signInWithGoogle(idToken: idToken);
    switch (res) {
      case Ok(:final value):
        state = AuthState.authenticated(value.user);
        return const Result.ok(null);
      case Err(:final failure):
        state = AuthState.unauthenticated(lastFailure: failure);
        return Result.err(failure);
    }
  }
```
(Проверь, что `UnknownFailure` имеет именованный параметр `message`; он используется в `login_page.dart` как `UnknownFailure(:final message)`. Если конструктор не `const` — убрать `const` перед `failure` и в `Result.err`.)

- [ ] **Step 9: Add signInWithGoogle to LoginController**

В `frontend/lib/features/auth/presentation/controllers/login_controller.dart` добавить метод (после `submit`):
```dart
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(submitting: true, failure: null);
    final res =
        await _ref.read(authControllerProvider.notifier).signInWithGoogle();
    final ok = res is Ok<void>;
    state = state.copyWith(
      submitting: false,
      failure: ok ? null : (res as Err<void>).failure,
    );
    return ok;
  }
```

- [ ] **Step 10: Verify compile + analyze**

Run: `cd frontend && flutter analyze lib/features/auth`
Expected: No issues (или только прежние, не связанные с правками).

- [ ] **Step 11: Commit**

```bash
git add frontend/lib/core/network/api_endpoints.dart frontend/lib/features/auth/data/datasources/auth_remote_data_source.dart frontend/lib/features/auth/domain/repositories/auth_repository.dart frontend/lib/features/auth/data/repositories/auth_repository_impl.dart frontend/lib/features/auth/presentation/providers/auth_providers.dart frontend/lib/features/auth/presentation/controllers/auth_controller.dart frontend/lib/features/auth/presentation/controllers/login_controller.dart frontend/test/features/auth/auth_repository_test.dart
git commit -m "feat(auth-fe): поток signInWithGoogle (datasource → repo → контроллеры)"
```

---

## Task F4: Рестайл экрана входа + кнопка Google

**Files:**
- Modify: `frontend/lib/features/auth/presentation/pages/login_page.dart`
- Test: `frontend/test/features/auth/login_page_test.dart`

- [ ] **Step 1: Write the failing widget test**

`frontend/test/features/auth/login_page_test.dart`:
```dart
import 'package:aifb/app/theme/app_theme.dart';
import 'package:aifb/features/auth/presentation/pages/login_page.dart';
import 'package:aifb/shared/widgets/hig_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap() => const ProviderScope(
        child: MaterialApp(home: LoginPage()),
      );

  testWidgets('показывает кнопку Google, форма email скрыта до клика по ссылке',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const LoginPage()),
      ),
    );

    expect(find.text('Войти через Google'), findsOneWidget);
    // классическая форма скрыта изначально
    expect(find.byType(HigTextField), findsNothing);

    await tester.tap(find.text('Войти с Email'));
    await tester.pumpAndSettle();

    // появились поля email + пароль
    expect(find.byType(HigTextField), findsNWidgets(2));
  });
}
```
(Переменная-хелпер `wrap()` не используется в самом тесте — можно удалить, оставлена для наглядности; при `flutter analyze` убрать неиспользуемое.)

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/auth/login_page_test.dart`
Expected: FAIL — нет текста «Войти через Google» / форма всегда видна.

- [ ] **Step 3: Rewrite login_page.dart with Google button + email-as-link**

Полностью заменить `frontend/lib/features/auth/presentation/pages/login_page.dart` на:
```dart
import 'package:aifb/app/router/routes.dart';
import 'package:aifb/app/theme/hig_colors.dart';
import 'package:aifb/core/errors/failure.dart';
import 'package:aifb/features/auth/presentation/controllers/login_controller.dart';
import 'package:aifb/features/auth/presentation/state/login_state.dart';
import 'package:aifb/shared/widgets/hig_button.dart';
import 'package:aifb/shared/widgets/hig_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showEmailForm = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_syncEmail);
    _passwordCtrl.addListener(_syncPassword);
  }

  @override
  void dispose() {
    _emailCtrl
      ..removeListener(_syncEmail)
      ..dispose();
    _passwordCtrl
      ..removeListener(_syncPassword)
      ..dispose();
    super.dispose();
  }

  void _syncEmail() =>
      ref.read(loginControllerProvider.notifier).emailChanged(_emailCtrl.text);

  void _syncPassword() => ref
      .read(loginControllerProvider.notifier)
      .passwordChanged(_passwordCtrl.text);

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref.read(loginControllerProvider.notifier).submit();
  }

  Future<void> _googleSignIn() async {
    FocusScope.of(context).unfocus();
    await ref.read(loginControllerProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final hig = HigColors.of(context);

    ref.listen<LoginState>(loginControllerProvider, (prev, next) {
      final f = next.failure;
      if (f != null && f != prev?.failure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_failureMessage(f))));
      }
    });

    return Scaffold(
      backgroundColor: hig.pageBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'AIFB',
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Вход',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    key: const Key('google_sign_in_button'),
                    onPressed: state.submitting ? null : _googleSignIn,
                    icon: SvgPicture.asset(
                      'assets/google_logo.svg',
                      height: 20,
                      width: 20,
                    ),
                    label: const Text('Войти через Google'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: hig.separator),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!_showEmailForm)
                  TextButton(
                    onPressed: () => setState(() => _showEmailForm = true),
                    child: const Text('Войти с Email'),
                  )
                else ...[
                  HigTextField(
                    controller: _emailCtrl,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    errorText: state.emailError,
                  ),
                  const SizedBox(height: 12),
                  HigTextField(
                    controller: _passwordCtrl,
                    label: 'Пароль',
                    obscureText: true,
                    errorText: state.passwordError,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          context.push(AppRoutes.forgotPassword.path),
                      child: const Text('Забыли пароль?'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  HigButton(
                    label: 'Войти',
                    loading: state.submitting,
                    onPressed: state.submitting ? null : _submit,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Нет аккаунта?'),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.register.path),
                      child: const Text('Создать аккаунт'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _failureMessage(Failure f) {
  return switch (f) {
    NetworkFailure(:final message) =>
      message ?? 'No internet connection. Please try again.',
    TimeoutFailure() => 'Request timed out. Please try again.',
    UnauthorizedFailure(:final message) =>
      message ?? 'Invalid email or password.',
    ForbiddenFailure(:final message) => message ?? 'Access denied.',
    NotFoundFailure(:final message) => message ?? 'Not found.',
    ConflictFailure(:final message) => message ?? 'Account already exists.',
    ValidationFailure(:final message) => message,
    ServerFailure(:final message) =>
      message ?? 'Server error. Please try again.',
    UnknownFailure(:final message) =>
      message ?? 'Something went wrong. Please try again.',
  };
}
```

- [ ] **Step 4: Run widget test to verify it passes**

Run: `cd frontend && flutter test test/features/auth/login_page_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/auth/presentation/pages/login_page.dart frontend/test/features/auth/login_page_test.dart
git commit -m "feat(auth-fe): рестайл экрана входа (кнопка Google + email-ссылка, ТЗ 5.2)"
```

---

## Task F5: Полная верификация + документация

**Files:**
- Modify: `docs/DEPLOYMENT.md`

- [ ] **Step 1: Run full backend test suite**

Run: `cd backend && ./gradlew test`
Expected: BUILD SUCCESSFUL — все тесты зелёные (требует Docker).

- [ ] **Step 2: Run full frontend test suite**

Run: `cd frontend && flutter test`
Expected: All tests passed.

- [ ] **Step 3: Run frontend analyzer**

Run: `cd frontend && flutter analyze`
Expected: No issues found (устранить любые предупреждения, внесённые правками — напр. неиспользуемый `wrap()` в тесте).

- [ ] **Step 4: Document Google env vars**

В `docs/DEPLOYMENT.md` добавить раздел про Google Sign-In env-переменные (backend: `GOOGLE_CLIENT_ID`, `GOOGLE_DEV_MODE`; frontend `.env`: те же). Описать: для демо `GOOGLE_DEV_MODE=true` (без реального Google-проекта); для прода `GOOGLE_DEV_MODE=false` + реальный `GOOGLE_CLIENT_ID` (web/server OAuth client), а на Android — отдельный OAuth client с SHA-1, при этом `serverClientId` = тот же web client. Добавить ровно после существующего раздела про переменные окружения; формулировки — в стиле документа.

- [ ] **Step 5: Commit**

```bash
git add docs/DEPLOYMENT.md
git commit -m "docs(deploy): переменные окружения Google Sign-In (dev/prod)"
```

---

## Definition of Done

- `POST /api/v1/auth/google` создаёт/находит/связывает пользователя и выдаёт JWT-сессию; невалидный/неверифицированный токен → 401 `AUTH_GOOGLE_TOKEN_INVALID`.
- Вход email+пароль для Google-аккаунта без пароля возвращает 401, а не 500.
- Экран входа показывает крупную кнопку «Войти через Google»; email — ссылка, раскрывающая классическую форму.
- Dev-режим работает в тестах и демо без реального Google-проекта; реальный путь включается `GOOGLE_DEV_MODE=false` + `GOOGLE_CLIENT_ID`.
- Полные наборы тестов (backend + frontend) зелёные; `flutter analyze` чист.
- Env-переменные Google задокументированы в `docs/DEPLOYMENT.md`.

## Out of scope (отдельные задачи)

- Пост-логин онбординг «создать/вступить в семью».
- iOS-настройка Google Sign-In; реальная публикация в Google Play.
- Формат пригласительного кода `FAM-XXXXXX`.
