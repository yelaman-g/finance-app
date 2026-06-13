# ИИ-помощник по финансам (ТЗ §6) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Подключить ИИ-помощника по финансам семьи: backend-модуль `ai` на Anthropic Claude API (за портом, с dev-режимом), который сам собирает финансовый контекст; эндпоинты чата, анализа бюджета, инсайтов, плана накоплений и напоминаний (`ai_reminders`); фронт — реальное подключение готового скелета + экраны «Чат/Анализ/Напоминания».

**Architecture:** Интеграция Claude спрятана за портом `FinanceAdvisor` (как verifier у Google): `DevFinanceAdvisor` (детерминированный, без сети — для тестов/демо) и `ClaudeFinanceAdvisor` (Anthropic Java SDK), выбор по `aifb.ai.dev-mode`. `FinanceContextBuilder` собирает контекст через существующий `StatisticsService`. Reminders — обычный CRUD по образцу `goal` (UUID + household-scope). Фронт переиспользует скелет `features/ai_assistant`, переключённый на аутентифицированный `dioProvider`.

**Tech Stack:** Java 21, Spring Boot 3.3.5, Spring Data JPA, Flyway, Anthropic Java SDK, Testcontainers + MockMvc · Flutter (Dart 3), Riverpod, Dio, go_router, flutter_test + mocktail.

**Спека:** `docs/superpowers/specs/2026-06-13-ai-assistant-design.md`

---

## Окружение и соглашения (для исполнителей)

- Worktree ONLY: `/Users/rik/Documents/asp/finance-app/.claude/worktrees/ai-assistant` (ветка `feature/ai-assistant`). Не трогать оригинальный чекаут.
- Backend gradle (JDK 21): `cd <worktree>/backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew <args>`. Если `gradlew` не исполняемый — `chmod +x backend/gradlew`. Docker запущен (Testcontainers).
- Frontend (flutter не в PATH): `export PATH="/opt/homebrew/bin:$PATH" && cd <worktree>/frontend && flutter <args>` (Flutter 3.44.0).
- **dev-режим по умолчанию (`aifb.ai.dev-mode=true`)** → backend-ИТ выполняются БЕЗ сети и без ключа Anthropic (работает `DevFinanceAdvisor`). Реальный Claude в тестах не вызывается.
- Конвенции backend: конверт `ApiResponse`, `@CurrentUser AuthPrincipal principal`, `ErrorCode`, `BaseEntity` (UUID id + `created_at`/`updated_at`/`version`), миграции в стиле V6 (`created_at/updated_at TIMESTAMPTZ NOT NULL DEFAULT now()`, `version BIGINT NOT NULL DEFAULT 0`). IT — extends `AbstractIntegrationTest`, аутентификация через `TestAuth.createUser()` → `user.bearer()`.
- **Anthropic Java SDK:** методы/классы берутся из справки `claude-api` (skill). Если сигнатура SDK в нужной версии отличается — свериться со справкой/репозиторием SDK, НЕ угадывать. Реальный путь не покрывается ИТ (нет ключа в CI) — компилируется и включается конфигом.

---

## Файловая структура

**Backend — создать (модуль `com.aifb.platform.ai`):**
- `ai/advisor/FinanceContext.java` — контекст (переиспользует statistics-DTO).
- `ai/advisor/FinanceContextBuilder.java` — сбор контекста.
- `ai/advisor/FinanceAdvisor.java` — порт + вложенные records (ChatTurn, ChatReply, Insight, BudgetAnalysis, SavingsPlanInput, SavingsPlan).
- `ai/advisor/DevFinanceAdvisor.java` — детерминированная реализация.
- `ai/advisor/ClaudeFinanceAdvisor.java` — реализация на Anthropic SDK.
- `ai/config/AiAdvisorConfig.java` — выбор бина по `aifb.ai.dev-mode`.
- `ai/service/AiService.java`, `ai/service/ReminderService.java`.
- `ai/domain/AiReminder.java`, `ai/repository/AiReminderRepository.java`.
- `ai/api/AiController.java` + `ai/api/dto/*` (ChatRequest, ChatTurnDto, AiMessageResponse, AnalyzeBudgetRequest, BudgetAnalysisResponse, InsightResponse, SavingsPlanRequest, SavingsPlanResponse, CreateReminderRequest, ReminderResponse).
- `backend/src/main/resources/db/migration/V15__ai_reminders.sql`.
- Тесты: `ai/advisor/DevFinanceAdvisorTest.java`, `ai/AiContextBuilderIT.java`, `ai/AiApiIT.java`, `ai/AiReminderApiIT.java`.

**Backend — изменить:** `build.gradle` (Anthropic SDK), `application.yml` (`aifb.ai.*`), `common/exception/ErrorCode.java` (AI_UNAVAILABLE).

**Frontend — создать:** data-DTO (plain-классы) и провайдеры/экраны для анализа и напоминаний (см. задачи F1–F5).

**Frontend — изменить:** `features/ai_assistant/...` (datasource, repo, providers, dependency-provider), `core/network/api_endpoints.dart`, `app/router/app_router.dart`, `features/more/presentation/pages/more_page.dart`, `docs/DEPLOYMENT.md`.

---

# ФАЗА A — BACKEND

## Task A1: Зависимость, конфиг, код ошибки

**Files:** Modify `backend/build.gradle`, `backend/src/main/resources/application.yml`, `backend/src/main/java/com/aifb/platform/common/exception/ErrorCode.java`

- [ ] **Step 1: build.gradle — Anthropic SDK**
В блок `dependencies { ... }` (после строки `google-api-client`) добавить:
```groovy
    implementation 'com.anthropic:anthropic-java:2.34.0'
```

- [ ] **Step 2: application.yml — блок aifb.ai**
В блок `aifb:` (после `verification:` / `google:`) добавить (отступ 2 пробела, как у соседей):
```yaml
  ai:
    model: ${ANTHROPIC_MODEL:claude-sonnet-4-6}
    dev-mode: ${AI_DEV_MODE:true}
    max-tokens: ${AI_MAX_TOKENS:2048}
    api-key: ${ANTHROPIC_API_KEY:}
```

- [ ] **Step 3: ErrorCode — AI_UNAVAILABLE**
В `ErrorCode.java` заменить последнюю константу (сейчас `AUTH_GOOGLE_TOKEN_INVALID(...)` оканчивается на `;`), добавив новую с запятой и новой последней с `;`:
```java
    AUTH_GOOGLE_TOKEN_INVALID("AUTH_GOOGLE_TOKEN_INVALID", HttpStatus.UNAUTHORIZED),
    AI_UNAVAILABLE("AI_UNAVAILABLE", HttpStatus.SERVICE_UNAVAILABLE);
```

- [ ] **Step 4: Compile**
Run: `cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew compileJava`
Expected: BUILD SUCCESSFUL (Anthropic SDK скачан).

- [ ] **Step 5: Commit**
```bash
git add backend/build.gradle backend/src/main/resources/application.yml backend/src/main/java/com/aifb/platform/common/exception/ErrorCode.java
git commit -m "chore(ai): Anthropic SDK, конфиг aifb.ai.*, код AI_UNAVAILABLE"
```

---

## Task A2: FinanceContext + FinanceContextBuilder

**Files:**
- Create `backend/src/main/java/com/aifb/platform/ai/advisor/FinanceContext.java`
- Create `backend/src/main/java/com/aifb/platform/ai/advisor/FinanceContextBuilder.java`
- Test `backend/src/test/java/com/aifb/platform/ai/AiContextBuilderIT.java`

Контекст переиспользует statistics-DTO (`SummaryResponse{income,expense,net}`, `CategoryBreakdownResponse{categoryId,name,color,total,percentage}`, `TrendPointResponse{month,income,expense}`) и `Currency`, `Scope`.

- [ ] **Step 1: FinanceContext.java**
```java
package com.aifb.platform.ai.advisor;

import com.aifb.platform.common.domain.Currency;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.finance.statistics.api.dto.CategoryBreakdownResponse;
import com.aifb.platform.finance.statistics.api.dto.SummaryResponse;
import com.aifb.platform.finance.statistics.api.dto.TrendPointResponse;

import java.util.List;

public record FinanceContext(
        Currency currency,
        Scope scope,
        SummaryResponse currentMonth,
        SummaryResponse previousMonth,
        List<CategoryBreakdownResponse> topExpenseCategories,
        List<TrendPointResponse> trend) {
}
```

- [ ] **Step 2: Write the failing test AiContextBuilderIT.java**
```java
package com.aifb.platform.ai;

import com.aifb.platform.ai.advisor.FinanceContext;
import com.aifb.platform.ai.advisor.FinanceContextBuilder;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.assertj.core.api.Assertions.assertThat;

class AiContextBuilderIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired FinanceContextBuilder builder;

    @Test
    void buildsContextForNewUserWithoutHousehold() {
        TestAuth.AuthedUser user = testAuth.createUser();
        FinanceContext ctx = builder.build(user.id(), null);

        assertThat(ctx).isNotNull();
        assertThat(ctx.scope()).isEqualTo(Scope.PERSONAL); // нет семьи → личный
        assertThat(ctx.currency()).isNotNull();             // дефолт KZT
        assertThat(ctx.currentMonth()).isNotNull();
        assertThat(ctx.previousMonth()).isNotNull();
        assertThat(ctx.topExpenseCategories()).isNotNull();
        assertThat(ctx.trend()).isNotNull();
    }
}
```
> `TestAuth.AuthedUser` — record `(UUID id, String email, String bearer)`: используй `user.id()` для UUID и `user.bearer()` для заголовка Authorization (проверено).

- [ ] **Step 3: Run test → FAIL (FinanceContextBuilder не существует, compile error)**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests "com.aifb.platform.ai.AiContextBuilderIT"`

- [ ] **Step 4: FinanceContextBuilder.java**
```java
package com.aifb.platform.ai.advisor;

import com.aifb.platform.auth.domain.User;
import com.aifb.platform.auth.repository.UserRepository;
import com.aifb.platform.auth.repository.UserSettingsRepository;
import com.aifb.platform.common.domain.Currency;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.statistics.service.StatisticsService;
import com.aifb.platform.household.service.HouseholdContextService;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Собирает финансовый контекст пользователя для подстановки в промпт Claude. */
@Component
public class FinanceContextBuilder {

    private final StatisticsService statistics;
    private final HouseholdContextService householdContext;
    private final UserRepository userRepository;
    private final UserSettingsRepository userSettingsRepository;

    public FinanceContextBuilder(StatisticsService statistics,
                                 HouseholdContextService householdContext,
                                 UserRepository userRepository,
                                 UserSettingsRepository userSettingsRepository) {
        this.statistics = statistics;
        this.householdContext = householdContext;
        this.userRepository = userRepository;
        this.userSettingsRepository = userSettingsRepository;
    }

    /** requested == null → эффективный scope: FAMILY если есть семья, иначе PERSONAL. */
    @Transactional(readOnly = true)
    public FinanceContext build(UUID userId, Scope requested) {
        Scope scope = resolveScope(userId, requested);
        LocalDate today = LocalDate.now();
        LocalDate curStart = today.withDayOfMonth(1);
        LocalDate prevStart = curStart.minusMonths(1);
        LocalDate prevEnd = curStart.minusDays(1);
        LocalDate trendStart = curStart.minusMonths(5);

        return new FinanceContext(
                currencyOf(userId),
                scope,
                statistics.summary(userId, curStart, today, scope),
                statistics.summary(userId, prevStart, prevEnd, scope),
                statistics.byCategory(userId, CategoryType.EXPENSE, curStart, today, scope),
                statistics.trend(userId, trendStart, today, scope));
    }

    public Scope resolveScope(UUID userId, Scope requested) {
        if (requested != null) {
            return requested;
        }
        return householdContext.membershipOrNull(userId) != null ? Scope.FAMILY : Scope.PERSONAL;
    }

    private Currency currencyOf(UUID userId) {
        return userRepository.findById(userId)
                .flatMap(userSettingsRepository::findByUser)
                .map(s -> s.getCurrency())
                .orElse(Currency.KZT);
    }
}
```
> Проверено: `UserSettingsRepository.findByUser(User)` → `Optional<UserSettings>`, `UserSettings.getCurrency()` → `Currency`. Цепочка `findById(userId).flatMap(userSettingsRepository::findByUser).map(UserSettings::getCurrency).orElse(Currency.KZT)` корректна.

- [ ] **Step 5: Run test → PASS**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests "com.aifb.platform.ai.AiContextBuilderIT"` → PASS.

- [ ] **Step 6: Commit**
```bash
git add backend/src/main/java/com/aifb/platform/ai/advisor/FinanceContext.java backend/src/main/java/com/aifb/platform/ai/advisor/FinanceContextBuilder.java backend/src/test/java/com/aifb/platform/ai/AiContextBuilderIT.java
git commit -m "feat(ai): FinanceContext + FinanceContextBuilder (сбор контекста по scope)"
```

---

## Task A3: Порт FinanceAdvisor + DevFinanceAdvisor

**Files:**
- Create `backend/src/main/java/com/aifb/platform/ai/advisor/FinanceAdvisor.java`
- Create `backend/src/main/java/com/aifb/platform/ai/advisor/DevFinanceAdvisor.java`
- Test `backend/src/test/java/com/aifb/platform/ai/advisor/DevFinanceAdvisorTest.java`

- [ ] **Step 1: FinanceAdvisor.java (порт + records)**
```java
package com.aifb.platform.ai.advisor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface FinanceAdvisor {

    ChatReply chat(FinanceContext ctx, List<ChatTurn> conversation);
    BudgetAnalysis analyzeBudget(FinanceContext ctx);
    List<Insight> insights(FinanceContext ctx);
    SavingsPlan savingsPlan(FinanceContext ctx, SavingsPlanInput input);

    record ChatTurn(String role, String content) {}                 // role: "user" | "ai"
    record ChatReply(String content, List<String> suggestedActions) {}
    record Insight(String title, String description, String type,   // type: recommendation|warning|prediction|achievement
                   BigDecimal impactValue, String impactLabel) {}
    record BudgetAnalysis(String analysis, List<String> tips) {}
    record SavingsPlanInput(String eventName, LocalDate eventDate,
                            BigDecimal targetAmount, BigDecimal savedAmount) {}
    record SavingsPlan(BigDecimal monthlyAmount, int monthsRemaining,
                       boolean feasible, String advice) {}
}
```

- [ ] **Step 2: Write the failing test DevFinanceAdvisorTest.java**
```java
package com.aifb.platform.ai.advisor;

import com.aifb.platform.common.domain.Currency;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.finance.statistics.api.dto.CategoryBreakdownResponse;
import com.aifb.platform.finance.statistics.api.dto.SummaryResponse;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class DevFinanceAdvisorTest {

    private final DevFinanceAdvisor advisor = new DevFinanceAdvisor();

    private FinanceContext ctx() {
        return new FinanceContext(
                Currency.KZT, Scope.PERSONAL,
                new SummaryResponse(new BigDecimal("500000"), new BigDecimal("300000"), new BigDecimal("200000")),
                new SummaryResponse(new BigDecimal("500000"), new BigDecimal("250000"), new BigDecimal("250000")),
                List.of(new CategoryBreakdownResponse(UUID.randomUUID(), "Еда", "#fff", new BigDecimal("120000"), 40.0)),
                List.of());
    }

    @Test
    void chatReturnsNonEmptyFinanceReply() {
        var reply = advisor.chat(ctx(), List.of(new FinanceAdvisor.ChatTurn("user", "Где я трачу больше всего?")));
        assertThat(reply.content()).isNotBlank();
        assertThat(reply.content()).contains("Еда"); // ссылается на топ-категорию
    }

    @Test
    void insightsDerivedFromContext() {
        var insights = advisor.insights(ctx());
        assertThat(insights).isNotEmpty();
        assertThat(insights).allSatisfy(i -> {
            assertThat(i.title()).isNotBlank();
            assertThat(i.type()).isIn("recommendation", "warning", "prediction", "achievement");
        });
    }

    @Test
    void savingsPlanComputesMonthlyAmount() {
        var plan = advisor.savingsPlan(ctx(), new FinanceAdvisor.SavingsPlanInput(
                "Подарок", LocalDate.now().plusMonths(4), new BigDecimal("150000"), new BigDecimal("30000")));
        assertThat(plan.monthsRemaining()).isGreaterThanOrEqualTo(1);
        assertThat(plan.monthlyAmount()).isGreaterThan(BigDecimal.ZERO); // (150000-30000)/месяцы
    }

    @Test
    void analyzeReturnsTextAndTips() {
        var a = advisor.analyzeBudget(ctx());
        assertThat(a.analysis()).isNotBlank();
        assertThat(a.tips()).isNotNull();
    }
}
```

- [ ] **Step 3: Run test → FAIL (DevFinanceAdvisor не существует)**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests "com.aifb.platform.ai.advisor.DevFinanceAdvisorTest"`

- [ ] **Step 4: DevFinanceAdvisor.java (детерминированный, без сети)**
```java
package com.aifb.platform.ai.advisor;

import com.aifb.platform.finance.statistics.api.dto.CategoryBreakdownResponse;
import com.aifb.platform.finance.statistics.api.dto.SummaryResponse;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;

/**
 * Детерминированная реализация без обращения к сети. Используется в dev-режиме
 * (aifb.ai.dev-mode=true) для тестов и демо без ключа Anthropic. Все ответы
 * считаются из реального финансового контекста.
 */
public class DevFinanceAdvisor implements FinanceAdvisor {

    @Override
    public ChatReply chat(FinanceContext ctx, List<ChatTurn> conversation) {
        SummaryResponse cur = ctx.currentMonth();
        String top = ctx.topExpenseCategories().isEmpty() ? "—"
                : ctx.topExpenseCategories().get(0).name();
        String cur3 = ctx.currency().name();
        String text = String.format(
                "За текущий месяц доход %s %s, расход %s %s, баланс %s %s. "
                        + "Крупнейшая категория расходов — «%s». "
                        + "Совет: держите расход в этой категории под контролем.",
                cur.income(), cur3, cur.expense(), cur3, cur.net(), cur3, top);
        return new ChatReply(text, List.of("Показать расходы по категориям", "Установить лимит"));
    }

    @Override
    public BudgetAnalysis analyzeBudget(FinanceContext ctx) {
        SummaryResponse cur = ctx.currentMonth();
        SummaryResponse prev = ctx.previousMonth();
        String c = ctx.currency().name();
        String analysis = String.format(
                "Текущий месяц: расход %s %s (прошлый: %s %s), баланс %s %s.",
                cur.expense(), c, prev.expense(), c, cur.net(), c);
        List<String> tips = new ArrayList<>();
        if (cur.expense().compareTo(prev.expense()) > 0) {
            tips.add("Расходы выросли по сравнению с прошлым месяцем — проверьте крупные категории.");
        }
        if (cur.net().signum() < 0) {
            tips.add("Баланс отрицательный — расходы превышают доходы.");
        }
        if (tips.isEmpty()) {
            tips.add("Бюджет под контролем — так держать.");
        }
        return new BudgetAnalysis(analysis, tips);
    }

    @Override
    public List<Insight> insights(FinanceContext ctx) {
        List<Insight> out = new ArrayList<>();
        if (!ctx.topExpenseCategories().isEmpty()) {
            CategoryBreakdownResponse top = ctx.topExpenseCategories().get(0);
            out.add(new Insight(
                    "Крупнейшая категория расходов",
                    String.format("«%s» — %.0f%% всех расходов месяца.", top.name(), top.percentage()),
                    top.percentage() >= 40.0 ? "warning" : "recommendation",
                    top.total(), null));
        }
        int cmp = ctx.currentMonth().expense().compareTo(ctx.previousMonth().expense());
        if (cmp > 0) {
            out.add(new Insight("Рост расходов",
                    "Расходы выше, чем в прошлом месяце.", "prediction", null, null));
        } else if (cmp < 0) {
            out.add(new Insight("Снижение расходов",
                    "Вы тратите меньше, чем в прошлом месяце. Отлично!", "achievement", null, null));
        }
        if (ctx.currentMonth().net().signum() >= 0) {
            out.add(new Insight("Положительный баланс",
                    "Доходы покрывают расходы в этом месяце.", "achievement",
                    ctx.currentMonth().net(), null));
        }
        return out;
    }

    @Override
    public SavingsPlan savingsPlan(FinanceContext ctx, SavingsPlanInput input) {
        long days = ChronoUnit.DAYS.between(LocalDate.now(), input.eventDate());
        int months = (int) Math.max(1, Math.ceil(days / 30.0));
        BigDecimal saved = input.savedAmount() == null ? BigDecimal.ZERO : input.savedAmount();
        BigDecimal remaining = input.targetAmount().subtract(saved).max(BigDecimal.ZERO);
        BigDecimal monthly = remaining.divide(BigDecimal.valueOf(months), 2, RoundingMode.HALF_UP);
        boolean feasible = monthly.compareTo(ctx.currentMonth().net().max(BigDecimal.ZERO)) <= 0;
        String advice = String.format(
                "До события «%s» ~%d мес. Нужно откладывать %s %s в месяц. %s",
                input.eventName(), months, monthly, ctx.currency().name(),
                feasible ? "Это реально при текущем балансе." : "Это выше текущего месячного баланса — пересмотрите план.");
        return new SavingsPlan(monthly, months, feasible, advice);
    }
}
```

- [ ] **Step 5: Run test → PASS (4 теста)**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests "com.aifb.platform.ai.advisor.DevFinanceAdvisorTest"`

- [ ] **Step 6: Commit**
```bash
git add backend/src/main/java/com/aifb/platform/ai/advisor/FinanceAdvisor.java backend/src/main/java/com/aifb/platform/ai/advisor/DevFinanceAdvisor.java backend/src/test/java/com/aifb/platform/ai/advisor/DevFinanceAdvisorTest.java
git commit -m "feat(ai): порт FinanceAdvisor + DevFinanceAdvisor (детерминированный, без сети)"
```

---

## Task A4: ClaudeFinanceAdvisor + выбор бина по конфигу

**Files:**
- Create `backend/src/main/java/com/aifb/platform/ai/advisor/ClaudeFinanceAdvisor.java`
- Create `backend/src/main/java/com/aifb/platform/ai/config/AiAdvisorConfig.java`

> Реальный путь Claude НЕ покрывается ИТ (нет ключа в CI). Цель задачи — он компилируется и выбирается конфигом. Чат — текст; инсайты/анализ/план — JSON-инструкция + разбор Jackson с безопасным фоллбэком (на ошибку парсинга/сети → бросить `DomainException(AI_UNAVAILABLE)` либо вернуть пустой результат для инсайтов).

- [ ] **Step 1: ClaudeFinanceAdvisor.java**
Системный промпт (ТЗ §6.5) + сериализованный контекст. Вызовы Anthropic SDK — по справке `claude-api` (Java): клиент `AnthropicOkHttpClient.builder().apiKey(key).build()`, запрос `client.messages().create(MessageCreateParams.builder().model(model).maxTokens(maxTokens).system(systemPrompt).addUserMessage(userText).build())`, ответ — `resp.content().stream().flatMap(b -> b.text().stream()).map(t -> t.text())...`.
```java
package com.aifb.platform.ai.advisor;

import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.common.exception.ErrorCode;
import com.anthropic.client.AnthropicClient;
import com.anthropic.client.okhttp.AnthropicOkHttpClient;
import com.anthropic.models.messages.Message;
import com.anthropic.models.messages.MessageCreateParams;

import java.util.List;

/**
 * Реальная реализация на Anthropic Java SDK. Активна при aifb.ai.dev-mode=false.
 * Системный промпт ограничивает модель темой финансов (ТЗ §6.2, §6.5).
 * ПРИМЕЧАНИЕ: точные имена методов SDK — по справке claude-api; при расхождении
 * версии свериться со справкой/репозиторием SDK, не угадывать.
 */
public class ClaudeFinanceAdvisor implements FinanceAdvisor {

    private static final String SYSTEM_PROMPT = """
            Ты финансовый помощник семейного приложения Family App. Помогаешь семье вести бюджет,
            планировать накопления и напоминать о важных событиях. Отвечай ТОЛЬКО на вопросы о
            финансах, бюджете и планировании. Если спрашивают о другом — вежливо объясни, что ты
            специализируешься только на финансах семьи. Используй данные о доходах и расходах из
            контекста запроса. Давай конкретные цифры и практические советы. Отвечай по-русски.
            """;

    private final AnthropicClient client;
    private final String model;
    private final long maxTokens;
    private final DevFinanceAdvisor fallback = new DevFinanceAdvisor();

    public ClaudeFinanceAdvisor(String apiKey, String model, long maxTokens) {
        this.client = AnthropicOkHttpClient.builder().apiKey(apiKey).build();
        this.model = model;
        this.maxTokens = maxTokens;
    }

    private String complete(String userText) {
        try {
            MessageCreateParams params = MessageCreateParams.builder()
                    .model(model)
                    .maxTokens(maxTokens)
                    .system(SYSTEM_PROMPT)
                    .addUserMessage(userText)
                    .build();
            Message resp = client.messages().create(params);
            StringBuilder sb = new StringBuilder();
            resp.content().stream()
                    .flatMap(b -> b.text().stream())
                    .forEach(t -> sb.append(t.text()));
            return sb.toString();
        } catch (Exception e) {
            throw new DomainException(ErrorCode.AI_UNAVAILABLE, "AI service unavailable");
        }
    }

    @Override
    public ChatReply chat(FinanceContext ctx, List<ChatTurn> conversation) {
        String last = conversation.isEmpty() ? "" : conversation.get(conversation.size() - 1).content();
        String prompt = serialize(ctx) + "\n\nВопрос пользователя: " + last;
        return new ChatReply(complete(prompt), List.of());
    }

    @Override
    public BudgetAnalysis analyzeBudget(FinanceContext ctx) {
        String text = complete(serialize(ctx) + "\n\nДай краткий анализ бюджета за месяц и 2-3 совета.");
        return new BudgetAnalysis(text, List.of());
    }

    @Override
    public List<Insight> insights(FinanceContext ctx) {
        // Инсайты — детерминированно из контекста (надёжно и без риска кривого JSON);
        // текстовую обвязку даёт модель только в чате/анализе.
        return fallback.insights(ctx);
    }

    @Override
    public SavingsPlan savingsPlan(FinanceContext ctx, SavingsPlanInput input) {
        // Арифметику считаем сами (детерминированно), формулировку — моделью.
        SavingsPlan base = fallback.savingsPlan(ctx, input);
        return base;
    }

    private String serialize(FinanceContext ctx) {
        String c = ctx.currency().name();
        return String.format(
                "Контекст (валюта %s, режим %s): текущий месяц доход=%s расход=%s баланс=%s; "
                        + "прошлый месяц расход=%s; топ-категории расходов=%s.",
                c, ctx.scope(), ctx.currentMonth().income(), ctx.currentMonth().expense(),
                ctx.currentMonth().net(), ctx.previousMonth().expense(),
                ctx.topExpenseCategories());
    }
}
```
> Инсайты/план в реальном режиме переиспользуют детерминированную арифметику `DevFinanceAdvisor` (надёжно). Чат/анализ — реальный Claude. Это сознательный компромисс надёжности (см. спека §12). Если позже нужен полностью модельный JSON — добавить structured outputs отдельной задачей.

- [ ] **Step 2: AiAdvisorConfig.java**
```java
package com.aifb.platform.ai.config;

import com.aifb.platform.ai.advisor.ClaudeFinanceAdvisor;
import com.aifb.platform.ai.advisor.DevFinanceAdvisor;
import com.aifb.platform.ai.advisor.FinanceAdvisor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AiAdvisorConfig {

    @Bean
    @ConditionalOnProperty(prefix = "aifb.ai", name = "dev-mode", havingValue = "true", matchIfMissing = true)
    public FinanceAdvisor devFinanceAdvisor() {
        return new DevFinanceAdvisor();
    }

    @Bean
    @ConditionalOnProperty(prefix = "aifb.ai", name = "dev-mode", havingValue = "false")
    public FinanceAdvisor claudeFinanceAdvisor(
            @Value("${aifb.ai.api-key:}") String apiKey,
            @Value("${aifb.ai.model:claude-sonnet-4-6}") String model,
            @Value("${aifb.ai.max-tokens:2048}") long maxTokens) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new IllegalStateException("ANTHROPIC_API_KEY must be set when aifb.ai.dev-mode=false");
        }
        return new ClaudeFinanceAdvisor(apiKey, model, maxTokens);
    }
}
```
> `matchIfMissing=true` оставлено сознательно: dev-режим — дефолт для CI/демо без ключа (в отличие от Google, где дефолт задаётся yml). Это безопасно: реальный режим требует явного `AI_DEV_MODE=false`.

- [ ] **Step 3: Compile + dev-тест ещё зелёный**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew compileJava test --tests "com.aifb.platform.ai.advisor.DevFinanceAdvisorTest"`
Expected: BUILD SUCCESSFUL.

- [ ] **Step 4: Commit**
```bash
git add backend/src/main/java/com/aifb/platform/ai/advisor/ClaudeFinanceAdvisor.java backend/src/main/java/com/aifb/platform/ai/config/AiAdvisorConfig.java
git commit -m "feat(ai): ClaudeFinanceAdvisor (Anthropic SDK) + выбор бина по aifb.ai.dev-mode"
```

---

## Task A5: Сущность AiReminder + миграция V15 + репозиторий

**Files:**
- Create `backend/src/main/resources/db/migration/V15__ai_reminders.sql`
- Create `backend/src/main/java/com/aifb/platform/ai/domain/AiReminder.java`
- Create `backend/src/main/java/com/aifb/platform/ai/repository/AiReminderRepository.java`

- [ ] **Step 1: V15__ai_reminders.sql** (стиль V6: created_at/updated_at/version)
```sql
CREATE TABLE ai_reminders (
    id                 UUID PRIMARY KEY,
    user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    household_id       UUID REFERENCES households(id) ON DELETE CASCADE,
    event_name         VARCHAR(200) NOT NULL,
    event_date         DATE NOT NULL,
    target_amount      NUMERIC(14,2),
    saved_amount       NUMERIC(14,2) NOT NULL DEFAULT 0,
    notify_days_before VARCHAR(60) NOT NULL DEFAULT '90,30,7,1',
    is_active          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    version            BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_ai_reminders_user ON ai_reminders (user_id);
CREATE INDEX idx_ai_reminders_household ON ai_reminders (household_id);
```
> Решение: `notify_days_before` хранится строкой CSV (`"90,30,7,1"`) — проще и портативнее, чем Postgres `INTEGER[]`/Hibernate `@Array`. DTO наружу — `List<Integer>` (парсинг в сущности).

- [ ] **Step 2: AiReminder.java**
```java
package com.aifb.platform.ai.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Entity
@Table(name = "ai_reminders")
public class AiReminder extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "household_id")
    private UUID householdId;

    @Column(name = "event_name", nullable = false, length = 200)
    private String eventName;

    @Column(name = "event_date", nullable = false)
    private LocalDate eventDate;

    @Column(name = "target_amount", precision = 14, scale = 2)
    private BigDecimal targetAmount;

    @Column(name = "saved_amount", nullable = false, precision = 14, scale = 2)
    private BigDecimal savedAmount = BigDecimal.ZERO;

    @Column(name = "notify_days_before", nullable = false, length = 60)
    private String notifyDaysBefore = "90,30,7,1";

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    protected AiReminder() {
    }

    public AiReminder(UUID userId, String eventName, LocalDate eventDate,
                      BigDecimal targetAmount, BigDecimal savedAmount, List<Integer> notifyDaysBefore) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.eventName = eventName;
        this.eventDate = eventDate;
        this.targetAmount = targetAmount;
        this.savedAmount = savedAmount == null ? BigDecimal.ZERO : savedAmount;
        if (notifyDaysBefore != null && !notifyDaysBefore.isEmpty()) {
            this.notifyDaysBefore = notifyDaysBefore.stream().map(String::valueOf)
                    .collect(Collectors.joining(","));
        }
    }

    public UUID getUserId() { return userId; }
    public UUID getHouseholdId() { return householdId; }
    public boolean isShared() { return householdId != null; }
    public void assignHousehold(UUID householdId) { this.householdId = householdId; }
    public String getEventName() { return eventName; }
    public LocalDate getEventDate() { return eventDate; }
    public BigDecimal getTargetAmount() { return targetAmount; }
    public BigDecimal getSavedAmount() { return savedAmount; }
    public boolean isActive() { return active; }

    public List<Integer> getNotifyDaysBefore() {
        if (notifyDaysBefore == null || notifyDaysBefore.isBlank()) {
            return List.of();
        }
        return Arrays.stream(notifyDaysBefore.split(","))
                .map(String::trim).filter(s -> !s.isEmpty())
                .map(Integer::valueOf).toList();
    }
}
```

- [ ] **Step 3: AiReminderRepository.java**
```java
package com.aifb.platform.ai.repository;

import com.aifb.platform.ai.domain.AiReminder;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface AiReminderRepository extends JpaRepository<AiReminder, UUID> {
    List<AiReminder> findByUserIdAndHouseholdIdIsNullOrderByEventDateAsc(UUID userId);
    List<AiReminder> findByHouseholdIdOrderByEventDateAsc(UUID householdId);
}
```

- [ ] **Step 4: Verify schema/entity (SmokeContextIT)**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests "com.aifb.platform.SmokeContextIT"`
Expected: PASS (Flyway применяет V15, JPA validate проходит).

- [ ] **Step 5: Commit**
```bash
git add backend/src/main/resources/db/migration/V15__ai_reminders.sql backend/src/main/java/com/aifb/platform/ai/domain/AiReminder.java backend/src/main/java/com/aifb/platform/ai/repository/AiReminderRepository.java
git commit -m "feat(ai): миграция V15 ai_reminders + сущность AiReminder + репозиторий"
```

---

## Task A6: AI DTO + AiService + ReminderService

**Files:**
- Create DTO в `backend/src/main/java/com/aifb/platform/ai/api/dto/`: `ChatTurnDto`, `ChatRequest`, `AiMessageResponse`, `AnalyzeBudgetRequest`, `BudgetAnalysisResponse`, `InsightResponse`, `SavingsPlanRequest`, `SavingsPlanResponse`, `CreateReminderRequest`, `ReminderResponse`
- Create `backend/src/main/java/com/aifb/platform/ai/service/AiService.java`
- Create `backend/src/main/java/com/aifb/platform/ai/service/ReminderService.java`

- [ ] **Step 1: DTO-записи**
`ChatTurnDto.java`:
```java
package com.aifb.platform.ai.api.dto;
import jakarta.validation.constraints.NotBlank;
public record ChatTurnDto(@NotBlank String role, @NotBlank String content) {}
```
`ChatRequest.java`:
```java
package com.aifb.platform.ai.api.dto;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;
public record ChatRequest(@NotEmpty @Valid List<ChatTurnDto> messages) {}
```
`AiMessageResponse.java`:
```java
package com.aifb.platform.ai.api.dto;
import java.util.List;
public record AiMessageResponse(String role, String content, List<String> suggestedActions) {}
```
`AnalyzeBudgetRequest.java`:
```java
package com.aifb.platform.ai.api.dto;
import com.aifb.platform.common.domain.Scope;
import java.time.LocalDate;
public record AnalyzeBudgetRequest(LocalDate from, LocalDate to, Scope scope) {}
```
`BudgetAnalysisResponse.java`:
```java
package com.aifb.platform.ai.api.dto;
import java.util.List;
public record BudgetAnalysisResponse(String analysis, List<String> tips) {}
```
`InsightResponse.java`:
```java
package com.aifb.platform.ai.api.dto;
import java.math.BigDecimal;
public record InsightResponse(String id, String title, String description, String type,
                              BigDecimal impactValue, String impactLabel) {}
```
`SavingsPlanRequest.java`:
```java
package com.aifb.platform.ai.api.dto;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;
public record SavingsPlanRequest(
        @NotBlank String eventName,
        @NotNull LocalDate eventDate,
        @NotNull @DecimalMin("0.01") BigDecimal targetAmount,
        BigDecimal savedAmount) {}
```
`SavingsPlanResponse.java`:
```java
package com.aifb.platform.ai.api.dto;
import java.math.BigDecimal;
public record SavingsPlanResponse(BigDecimal monthlyAmount, int monthsRemaining,
                                  boolean feasible, String advice) {}
```
`CreateReminderRequest.java`:
```java
package com.aifb.platform.ai.api.dto;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
public record CreateReminderRequest(
        @NotBlank String eventName,
        @NotNull LocalDate eventDate,
        BigDecimal targetAmount,
        BigDecimal savedAmount,
        List<Integer> notifyDaysBefore,
        boolean shared) {}
```
`ReminderResponse.java` (производные поля считаются в сервисе):
```java
package com.aifb.platform.ai.api.dto;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
public record ReminderResponse(
        UUID id, String eventName, LocalDate eventDate,
        BigDecimal targetAmount, BigDecimal savedAmount, List<Integer> notifyDaysBefore,
        boolean isActive, boolean shared,
        long daysUntil, int monthsRemaining, BigDecimal monthlyNeeded, double progressPercent) {}
```

- [ ] **Step 2: AiService.java**
```java
package com.aifb.platform.ai.service;

import com.aifb.platform.ai.advisor.FinanceAdvisor;
import com.aifb.platform.ai.advisor.FinanceContext;
import com.aifb.platform.ai.advisor.FinanceContextBuilder;
import com.aifb.platform.ai.api.dto.*;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class AiService {

    private final FinanceContextBuilder contextBuilder;
    private final FinanceAdvisor advisor;

    public AiService(FinanceContextBuilder contextBuilder, FinanceAdvisor advisor) {
        this.contextBuilder = contextBuilder;
        this.advisor = advisor;
    }

    public AiMessageResponse chat(UUID userId, ChatRequest request) {
        FinanceContext ctx = contextBuilder.build(userId, null);
        List<FinanceAdvisor.ChatTurn> turns = request.messages().stream()
                .map(m -> new FinanceAdvisor.ChatTurn(m.role(), m.content())).toList();
        FinanceAdvisor.ChatReply reply = advisor.chat(ctx, turns);
        return new AiMessageResponse("ai", reply.content(), reply.suggestedActions());
    }

    public BudgetAnalysisResponse analyzeBudget(UUID userId, AnalyzeBudgetRequest request) {
        FinanceContext ctx = contextBuilder.build(userId, request == null ? null : request.scope());
        FinanceAdvisor.BudgetAnalysis a = advisor.analyzeBudget(ctx);
        return new BudgetAnalysisResponse(a.analysis(), a.tips());
    }

    public List<InsightResponse> insights(UUID userId) {
        FinanceContext ctx = contextBuilder.build(userId, null);
        List<FinanceAdvisor.Insight> list = advisor.insights(ctx);
        return java.util.stream.IntStream.range(0, list.size())
                .mapToObj(i -> {
                    FinanceAdvisor.Insight x = list.get(i);
                    return new InsightResponse(String.valueOf(i), x.title(), x.description(),
                            x.type(), x.impactValue(), x.impactLabel());
                }).toList();
    }

    public SavingsPlanResponse savingsPlan(UUID userId, SavingsPlanRequest request) {
        FinanceContext ctx = contextBuilder.build(userId, null);
        FinanceAdvisor.SavingsPlan p = advisor.savingsPlan(ctx,
                new FinanceAdvisor.SavingsPlanInput(request.eventName(), request.eventDate(),
                        request.targetAmount(), request.savedAmount()));
        return new SavingsPlanResponse(p.monthlyAmount(), p.monthsRemaining(), p.feasible(), p.advice());
    }
}
```

- [ ] **Step 3: ReminderService.java** (CRUD + расчёт статуса, по образцу GoalService)
```java
package com.aifb.platform.ai.service;

import com.aifb.platform.ai.api.dto.CreateReminderRequest;
import com.aifb.platform.ai.api.dto.ReminderResponse;
import com.aifb.platform.ai.domain.AiReminder;
import com.aifb.platform.ai.repository.AiReminderRepository;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

@Service
public class ReminderService {

    private final AiReminderRepository repository;
    private final HouseholdContextService householdContext;

    public ReminderService(AiReminderRepository repository, HouseholdContextService householdContext) {
        this.repository = repository;
        this.householdContext = householdContext;
    }

    @Transactional(readOnly = true)
    public List<ReminderResponse> list(UUID userId, Scope scope) {
        List<AiReminder> reminders;
        if (scope == Scope.FAMILY) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            reminders = ctx == null ? List.of()
                    : repository.findByHouseholdIdOrderByEventDateAsc(ctx.householdId());
        } else {
            reminders = repository.findByUserIdAndHouseholdIdIsNullOrderByEventDateAsc(userId);
        }
        return reminders.stream().map(this::toResponse).toList();
    }

    @Transactional
    public ReminderResponse create(UUID userId, CreateReminderRequest req) {
        AiReminder reminder = new AiReminder(userId, req.eventName(), req.eventDate(),
                req.targetAmount(), req.savedAmount(), req.notifyDaysBefore());
        if (req.shared()) {
            HouseholdContext ctx = householdContext.requireManageSharedContent(userId);
            reminder.assignHousehold(ctx.householdId());
        }
        return toResponse(repository.save(reminder));
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        AiReminder reminder = repository.findById(id)
                .orElseThrow(() -> new NotFoundException("Напоминание не найдено"));
        if (reminder.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null || !ctx.householdId().equals(reminder.getHouseholdId())) {
                throw new NotFoundException("Напоминание не найдено");
            }
            if (!ctx.canManageSharedContent()) {
                throw new ForbiddenException("Недостаточно прав");
            }
        } else if (!userId.equals(reminder.getUserId())) {
            throw new NotFoundException("Напоминание не найдено");
        }
        repository.delete(reminder);
    }

    private ReminderResponse toResponse(AiReminder r) {
        long days = Math.max(0, ChronoUnit.DAYS.between(LocalDate.now(), r.getEventDate()));
        int months = (int) Math.max(1, Math.ceil(days / 30.0));
        BigDecimal target = r.getTargetAmount();
        BigDecimal monthlyNeeded = BigDecimal.ZERO;
        double progress = 0.0;
        if (target != null && target.signum() > 0) {
            BigDecimal remaining = target.subtract(r.getSavedAmount()).max(BigDecimal.ZERO);
            monthlyNeeded = remaining.divide(BigDecimal.valueOf(months), 2, RoundingMode.HALF_UP);
            progress = Math.min(100.0, r.getSavedAmount().multiply(BigDecimal.valueOf(100))
                    .divide(target, 1, RoundingMode.HALF_UP).doubleValue());
        }
        return new ReminderResponse(r.getId(), r.getEventName(), r.getEventDate(),
                target, r.getSavedAmount(), r.getNotifyDaysBefore(), r.isActive(), r.isShared(),
                days, months, monthlyNeeded, progress);
    }
}
```

- [ ] **Step 4: Compile**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew compileJava`
Expected: BUILD SUCCESSFUL.

- [ ] **Step 5: Commit**
```bash
git add backend/src/main/java/com/aifb/platform/ai/api/dto backend/src/main/java/com/aifb/platform/ai/service
git commit -m "feat(ai): DTO + AiService (чат/анализ/инсайты/план) + ReminderService (CRUD+статус)"
```

---

## Task A7: AiController + падающий AiApiIT → зелёный

**Files:**
- Create `backend/src/main/java/com/aifb/platform/ai/api/AiController.java`
- Test `backend/src/test/java/com/aifb/platform/ai/AiApiIT.java`

- [ ] **Step 1: Write the failing test AiApiIT.java** (dev-режим активен по умолчанию)
```java
package com.aifb.platform.ai;

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

class AiApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;

    @Test
    void chatRequiresAuth() throws Exception {
        mockMvc.perform(post("/api/v1/ai/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"messages\":[{\"role\":\"user\",\"content\":\"привет\"}]}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void chatReturnsAiMessage() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        mockMvc.perform(post("/api/v1/ai/chat")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"messages\":[{\"role\":\"user\",\"content\":\"Где трачу больше всего?\"}]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.role").value("ai"))
                .andExpect(jsonPath("$.data.content").isNotEmpty());
    }

    @Test
    void insightsReturnsList() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        mockMvc.perform(get("/api/v1/ai/insights")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray());
    }

    @Test
    void analyzeBudgetReturnsAnalysis() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        mockMvc.perform(post("/api/v1/ai/analyze-budget")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.analysis").isNotEmpty());
    }

    @Test
    void savingsPlanComputesMonthly() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        mockMvc.perform(post("/api/v1/ai/savings-plan")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"eventName\":\"Подарок\",\"eventDate\":\"%s\",\"targetAmount\":150000,\"savedAmount\":30000}"
                                .formatted(java.time.LocalDate.now().plusMonths(4))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.monthsRemaining").isNumber())
                .andExpect(jsonPath("$.data.monthlyAmount").isNumber());
    }
}
```

- [ ] **Step 2: Run → FAIL (нет эндпоинтов /ai/*)**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests "com.aifb.platform.ai.AiApiIT"`

- [ ] **Step 3: AiController.java**
```java
package com.aifb.platform.ai.api;

import com.aifb.platform.ai.api.dto.*;
import com.aifb.platform.ai.service.AiService;
import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/ai")
public class AiController {

    private final AiService aiService;

    public AiController(AiService aiService) {
        this.aiService = aiService;
    }

    @PostMapping("/chat")
    public ApiResponse<AiMessageResponse> chat(@CurrentUser AuthPrincipal principal,
                                               @Valid @RequestBody ChatRequest request) {
        return ApiResponse.ok(aiService.chat(principal.userId(), request));
    }

    @PostMapping("/analyze-budget")
    public ApiResponse<BudgetAnalysisResponse> analyze(@CurrentUser AuthPrincipal principal,
                                                       @RequestBody(required = false) AnalyzeBudgetRequest request) {
        return ApiResponse.ok(aiService.analyzeBudget(principal.userId(), request));
    }

    @GetMapping("/insights")
    public ApiResponse<List<InsightResponse>> insights(@CurrentUser AuthPrincipal principal) {
        return ApiResponse.ok(aiService.insights(principal.userId()));
    }

    @PostMapping("/savings-plan")
    public ApiResponse<SavingsPlanResponse> savingsPlan(@CurrentUser AuthPrincipal principal,
                                                        @Valid @RequestBody SavingsPlanRequest request) {
        return ApiResponse.ok(aiService.savingsPlan(principal.userId(), request));
    }
}
```
> `/api/v1/ai/**` НЕ добавляется в `PUBLIC_ENDPOINTS` — требует JWT (тест `chatRequiresAuth` это проверяет).

- [ ] **Step 4: Run → PASS (5 тестов)**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests "com.aifb.platform.ai.AiApiIT"`

- [ ] **Step 5: Commit**
```bash
git add backend/src/main/java/com/aifb/platform/ai/api/AiController.java backend/src/test/java/com/aifb/platform/ai/AiApiIT.java
git commit -m "feat(ai): эндпоинты /ai/chat, /analyze-budget, /insights, /savings-plan"
```

---

## Task A8: Эндпоинты напоминаний + падающий AiReminderApiIT → зелёный + полный прогон

**Files:**
- Modify `backend/src/main/java/com/aifb/platform/ai/api/AiController.java` (добавить reminders-эндпоинты)
- Test `backend/src/test/java/com/aifb/platform/ai/AiReminderApiIT.java`

- [ ] **Step 1: Write the failing test AiReminderApiIT.java**
```java
package com.aifb.platform.ai;

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

class AiReminderApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired ObjectMapper objectMapper;

    @Test
    void createListDeleteReminderWithStatus() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();

        MvcResult created = mockMvc.perform(post("/api/v1/ai/reminders")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"eventName\":\"День рождения\",\"eventDate\":\"%s\",\"targetAmount\":30000,\"savedAmount\":10000}"
                                .formatted(java.time.LocalDate.now().plusMonths(3))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.eventName").value("День рождения"))
                .andExpect(jsonPath("$.data.monthlyNeeded").isNumber())
                .andExpect(jsonPath("$.data.progressPercent").isNumber())
                .andReturn();
        String id = objectMapper.readTree(created.getResponse().getContentAsString())
                .path("data").path("id").asText();

        mockMvc.perform(get("/api/v1/ai/reminders")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].eventName").value("День рождения"));

        mockMvc.perform(delete("/api/v1/ai/reminders/" + id)
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk());
    }

    @Test
    void remindersRequireAuth() throws Exception {
        mockMvc.perform(get("/api/v1/ai/reminders")).andExpect(status().isUnauthorized());
    }
}
```

- [ ] **Step 2: Run → FAIL (нет reminders-эндпоинтов)**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests "com.aifb.platform.ai.AiReminderApiIT"`

- [ ] **Step 3: Добавить в AiController** инжекцию `ReminderService` и эндпоинты
В конструктор добавить `ReminderService reminderService` (поле + присваивание), импорты `com.aifb.platform.ai.service.ReminderService`, `com.aifb.platform.common.domain.Scope`, `java.util.UUID`. Добавить методы:
```java
    @GetMapping("/reminders")
    public ApiResponse<List<ReminderResponse>> reminders(
            @CurrentUser AuthPrincipal principal,
            @RequestParam(defaultValue = "PERSONAL") Scope scope) {
        return ApiResponse.ok(reminderService.list(principal.userId(), scope));
    }

    @PostMapping("/reminders")
    public ApiResponse<ReminderResponse> createReminder(
            @CurrentUser AuthPrincipal principal,
            @Valid @RequestBody CreateReminderRequest request) {
        return ApiResponse.ok(reminderService.create(principal.userId(), request));
    }

    @DeleteMapping("/reminders/{id}")
    public ApiResponse<Void> deleteReminder(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id) {
        reminderService.delete(principal.userId(), id);
        return ApiResponse.ok(null);
    }
```

- [ ] **Step 4: Run → PASS**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test --tests "com.aifb.platform.ai.AiReminderApiIT"`

- [ ] **Step 5: Полный backend-прогон (без регрессий)**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test`
Expected: BUILD SUCCESSFUL (все прежние + новые AI-тесты).

- [ ] **Step 6: Commit**
```bash
git add backend/src/main/java/com/aifb/platform/ai/api/AiController.java backend/src/test/java/com/aifb/platform/ai/AiReminderApiIT.java
git commit -m "feat(ai): CRUD напоминаний /ai/reminders (scope, расчёт статуса)"
```

---

# ФАЗА B — FRONTEND

## Task F1: Data-слой — endpoints, DTO, datasource (реальные вызовы)

**Files:**
- Modify `frontend/lib/core/network/api_endpoints.dart`
- Create `frontend/lib/features/ai_assistant/data/dto/ai_dtos.dart` (plain-классы с fromJson/toJson)
- Modify `frontend/lib/features/ai_assistant/data/data_sources/ai_remote_data_source.dart`
- Modify `frontend/lib/features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart`
- Modify `frontend/lib/features/ai_assistant/domain/repositories/ai_assistant_repository.dart`
- Modify `frontend/lib/features/ai_assistant/presentation/providers/ai_dependency_provider.dart`
- Test `frontend/test/features/ai_assistant/ai_repository_test.dart`

> Контракт чата stateless: фронт шлёт историю. Меняем `sendMessage(String)` → `sendMessage(String message, List<AiMessage> history)`. Инсайты/анализ/план/напоминания — новые методы. DTO — plain-классы (без freezed/build_runner), как доменные сущности.

- [ ] **Step 1: api_endpoints.dart** — в секцию after Categorization добавить:
```dart
  // AI assistant
  static const String aiChat = '/ai/chat';
  static const String aiInsights = '/ai/insights';
  static const String aiAnalyzeBudget = '/ai/analyze-budget';
  static const String aiSavingsPlan = '/ai/savings-plan';
  static const String aiReminders = '/ai/reminders';
```

- [ ] **Step 2: ai_dtos.dart** (plain-классы анализа/плана/напоминания)
```dart
class BudgetAnalysis {
  const BudgetAnalysis({required this.analysis, required this.tips});
  final String analysis;
  final List<String> tips;
  factory BudgetAnalysis.fromJson(Map<String, dynamic> j) => BudgetAnalysis(
        analysis: j['analysis'] as String? ?? '',
        tips: (j['tips'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      );
}

class SavingsPlan {
  const SavingsPlan({
    required this.monthlyAmount,
    required this.monthsRemaining,
    required this.feasible,
    required this.advice,
  });
  final double monthlyAmount;
  final int monthsRemaining;
  final bool feasible;
  final String advice;
  factory SavingsPlan.fromJson(Map<String, dynamic> j) => SavingsPlan(
        monthlyAmount: (j['monthlyAmount'] as num?)?.toDouble() ?? 0,
        monthsRemaining: (j['monthsRemaining'] as num?)?.toInt() ?? 0,
        feasible: j['feasible'] as bool? ?? false,
        advice: j['advice'] as String? ?? '',
      );
}

class Reminder {
  const Reminder({
    required this.id,
    required this.eventName,
    required this.eventDate,
    this.targetAmount,
    required this.savedAmount,
    required this.daysUntil,
    required this.monthsRemaining,
    required this.monthlyNeeded,
    required this.progressPercent,
  });
  final String id;
  final String eventName;
  final DateTime eventDate;
  final double? targetAmount;
  final double savedAmount;
  final int daysUntil;
  final int monthsRemaining;
  final double monthlyNeeded;
  final double progressPercent;
  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'] as String,
        eventName: j['eventName'] as String,
        eventDate: DateTime.parse(j['eventDate'] as String),
        targetAmount: (j['targetAmount'] as num?)?.toDouble(),
        savedAmount: (j['savedAmount'] as num?)?.toDouble() ?? 0,
        daysUntil: (j['daysUntil'] as num?)?.toInt() ?? 0,
        monthsRemaining: (j['monthsRemaining'] as num?)?.toInt() ?? 1,
        monthlyNeeded: (j['monthlyNeeded'] as num?)?.toDouble() ?? 0,
        progressPercent: (j['progressPercent'] as num?)?.toDouble() ?? 0,
      );
}
```

- [ ] **Step 3: Repository interface** (`ai_assistant_repository.dart`) — заменить целиком:
```dart
import '../entities/ai_message.dart';
import '../entities/insight_model.dart';
import '../../data/dto/ai_dtos.dart';

abstract class AiAssistantRepository {
  Future<AiMessage> sendMessage(String message, List<AiMessage> history);
  Future<List<InsightModel>> getFinancialInsights();
  Future<BudgetAnalysis> analyzeBudget();
  Future<SavingsPlan> savingsPlan({
    required String eventName,
    required DateTime eventDate,
    required double targetAmount,
    double? savedAmount,
  });
  Future<List<Reminder>> getReminders();
  Future<Reminder> createReminder({
    required String eventName,
    required DateTime eventDate,
    double? targetAmount,
    double? savedAmount,
  });
  Future<void> deleteReminder(String id);
}
```
> `getChatHistory()` убран: историю держит `AiChatNotifier` локально; приветствие генерируется на фронте (см. F2).

- [ ] **Step 4: datasource** (`ai_remote_data_source.dart`) — заменить целиком (реальные вызовы):
```dart
import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/ai_message.dart';
import '../../domain/entities/insight_model.dart';
import '../dto/ai_dtos.dart';

abstract class AiRemoteDataSource {
  Future<AiMessage> sendMessage(String message, List<AiMessage> history);
  Future<List<InsightModel>> getFinancialInsights();
  Future<BudgetAnalysis> analyzeBudget();
  Future<SavingsPlan> savingsPlan(Map<String, dynamic> body);
  Future<List<Reminder>> getReminders();
  Future<Reminder> createReminder(Map<String, dynamic> body);
  Future<void> deleteReminder(String id);
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  AiRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  String _role(MessageRole r) => r == MessageRole.user ? 'user' : 'ai';

  @override
  Future<AiMessage> sendMessage(String message, List<AiMessage> history) async {
    final msgs = <Map<String, dynamic>>[
      for (final m in history)
        if (!m.isTyping) {'role': _role(m.role), 'content': m.content},
      {'role': 'user', 'content': message},
    ];
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.aiChat,
      data: {'messages': msgs},
    );
    final d = _unwrap(res.data);
    return AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: d['content'] as String? ?? '',
      role: MessageRole.ai,
      timestamp: DateTime.now(),
      suggestedActions:
          (d['suggestedActions'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }

  @override
  Future<List<InsightModel>> getFinancialInsights() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.aiInsights);
    final list = _unwrapList(res.data);
    return list.map((j) => _insight(j as Map<String, dynamic>)).toList();
  }

  @override
  Future<BudgetAnalysis> analyzeBudget() async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.aiAnalyzeBudget,
      data: <String, dynamic>{},
    );
    return BudgetAnalysis.fromJson(_unwrap(res.data));
  }

  @override
  Future<SavingsPlan> savingsPlan(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.aiSavingsPlan,
      data: body,
    );
    return SavingsPlan.fromJson(_unwrap(res.data));
  }

  @override
  Future<List<Reminder>> getReminders() async {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.aiReminders);
    return _unwrapList(res.data).map((j) => Reminder.fromJson(j as Map<String, dynamic>)).toList();
  }

  @override
  Future<Reminder> createReminder(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(ApiEndpoints.aiReminders, data: body);
    return Reminder.fromJson(_unwrap(res.data));
  }

  @override
  Future<void> deleteReminder(String id) async {
    await _dio.delete<void>('${ApiEndpoints.aiReminders}/$id');
  }

  InsightModel _insight(Map<String, dynamic> j) {
    final typeStr = (j['type'] as String? ?? 'recommendation');
    final type = InsightType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => InsightType.recommendation,
    );
    return InsightModel(
      id: j['id']?.toString() ?? '',
      title: j['title'] as String? ?? '',
      description: j['description'] as String? ?? '',
      type: type,
      impactValue: (j['impactValue'] as num?)?.toDouble(),
      impactLabel: j['impactLabel'] as String?,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is Map<String, dynamic>) return data;
    throw DioException(requestOptions: RequestOptions(), message: 'Malformed envelope');
  }

  List<dynamic> _unwrapList(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is List) return data;
    throw DioException(requestOptions: RequestOptions(), message: 'Malformed envelope');
  }
}
```

- [ ] **Step 5: repository impl** (`ai_assistant_repository_impl.dart`) — заменить целиком:
```dart
import '../../domain/entities/ai_message.dart';
import '../../domain/entities/insight_model.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../data_sources/ai_remote_data_source.dart';
import '../dto/ai_dtos.dart';

class AiAssistantRepositoryImpl implements AiAssistantRepository {
  AiAssistantRepositoryImpl(this._remote);
  final AiRemoteDataSource _remote;

  @override
  Future<AiMessage> sendMessage(String message, List<AiMessage> history) =>
      _remote.sendMessage(message, history);

  @override
  Future<List<InsightModel>> getFinancialInsights() => _remote.getFinancialInsights();

  @override
  Future<BudgetAnalysis> analyzeBudget() => _remote.analyzeBudget();

  @override
  Future<SavingsPlan> savingsPlan({
    required String eventName,
    required DateTime eventDate,
    required double targetAmount,
    double? savedAmount,
  }) =>
      _remote.savingsPlan({
        'eventName': eventName,
        'eventDate': eventDate.toIso8601String().split('T').first,
        'targetAmount': targetAmount,
        if (savedAmount != null) 'savedAmount': savedAmount,
      });

  @override
  Future<List<Reminder>> getReminders() => _remote.getReminders();

  @override
  Future<Reminder> createReminder({
    required String eventName,
    required DateTime eventDate,
    double? targetAmount,
    double? savedAmount,
  }) =>
      _remote.createReminder({
        'eventName': eventName,
        'eventDate': eventDate.toIso8601String().split('T').first,
        if (targetAmount != null) 'targetAmount': targetAmount,
        if (savedAmount != null) 'savedAmount': savedAmount,
      });

  @override
  Future<void> deleteReminder(String id) => _remote.deleteReminder(id);
}
```

- [ ] **Step 6: dependency provider** (`ai_dependency_provider.dart`) — переключить на аутентифицированный `dioProvider`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/data_sources/ai_remote_data_source.dart';
import '../../data/repositories/ai_assistant_repository_impl.dart';
import '../../domain/repositories/ai_assistant_repository.dart';

final aiRemoteDataSourceProvider = Provider<AiRemoteDataSource>((ref) {
  return AiRemoteDataSourceImpl(ref.watch(dioProvider));
});

final aiAssistantRepositoryProvider = Provider<AiAssistantRepository>((ref) {
  return AiAssistantRepositoryImpl(ref.watch(aiRemoteDataSourceProvider));
});
```
> Удалён `aiDioProvider` (бесполезный неаутентифицированный `Dio()`); теперь используется общий `dioProvider` с JWT-интерсептором.

- [ ] **Step 7: Write the failing repo test** `frontend/test/features/ai_assistant/ai_repository_test.dart`
```dart
import 'package:aifb/features/ai_assistant/data/dto/ai_dtos.dart';
import 'package:aifb/features/ai_assistant/data/data_sources/ai_remote_data_source.dart';
import 'package:aifb/features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart';
import 'package:aifb/features/ai_assistant/domain/entities/ai_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements AiRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late AiAssistantRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = AiAssistantRepositoryImpl(remote);
  });

  test('sendMessage forwards history and returns ai message', () async {
    final reply = AiMessage(
      id: '1', content: 'ответ', role: MessageRole.ai, timestamp: DateTime.now(),
    );
    when(() => remote.sendMessage('вопрос', any())).thenAnswer((_) async => reply);
    final res = await repo.sendMessage('вопрос', const []);
    expect(res.content, 'ответ');
  });

  test('createReminder builds body and returns reminder', () async {
    final r = Reminder(
      id: 'r1', eventName: 'ДР', eventDate: DateTime(2026, 9, 1),
      savedAmount: 0, daysUntil: 80, monthsRemaining: 3, monthlyNeeded: 1000, progressPercent: 0,
    );
    when(() => remote.createReminder(any())).thenAnswer((_) async => r);
    final res = await repo.createReminder(
        eventName: 'ДР', eventDate: DateTime(2026, 9, 1), targetAmount: 30000);
    expect(res.eventName, 'ДР');
    verify(() => remote.createReminder(any())).called(1);
  });
}
```

- [ ] **Step 8: Run repo test + analyze** (нет ошибок)
`export PATH="/opt/homebrew/bin:$PATH" && cd frontend && flutter test test/features/ai_assistant/ai_repository_test.dart`
`... && flutter analyze lib/features/ai_assistant test/features/ai_assistant` (info-уровень предсуществующего стиля допустим; ошибок быть не должно).

- [ ] **Step 9: Commit**
```bash
git add frontend/lib/core/network/api_endpoints.dart frontend/lib/features/ai_assistant/data frontend/lib/features/ai_assistant/domain/repositories/ai_assistant_repository.dart frontend/lib/features/ai_assistant/presentation/providers/ai_dependency_provider.dart frontend/test/features/ai_assistant/ai_repository_test.dart
git commit -m "feat(ai-fe): data-слой на реальные эндпоинты /ai/* (чат+история, инсайты, анализ, план, напоминания)"
```

---

## Task F2: Провайдеры — чат шлёт историю, новые провайдеры анализа/напоминаний

**Files:**
- Modify `frontend/lib/features/ai_assistant/presentation/providers/ai_chat_provider.dart`
- Modify `frontend/lib/features/ai_assistant/presentation/providers/ai_insights_provider.dart` (если нужно — оставить как есть, метод не менялся по имени)
- Create `frontend/lib/features/ai_assistant/presentation/providers/ai_extra_providers.dart`

- [ ] **Step 1: ai_chat_provider.dart** — приветствие на фронте + передача истории. Заменить `build()` и вызов `sendMessage`:
В `build()` вернуть локальное приветствие (без сетевого `getChatHistory`):
```dart
  @override
  FutureOr<List<AiMessage>> build() async {
    return [
      AiMessage(
        id: 'welcome',
        content: 'Здравствуйте! Я ваш ИИ-помощник по финансам. Спросите про бюджет, расходы или накопления.',
        role: MessageRole.ai,
        timestamp: DateTime.now(),
      ),
    ];
  }
```
В `sendMessage(text)` заменить вызов репозитория, передав историю:
```dart
      final response = await repo.sendMessage(text, previousState);
```
(остальная оптимистичная логика остаётся.)

- [ ] **Step 2: ai_extra_providers.dart** — провайдеры анализа и напоминаний (без codegen):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dto/ai_dtos.dart';
import 'ai_dependency_provider.dart';

final budgetAnalysisProvider = FutureProvider.autoDispose<BudgetAnalysis>((ref) {
  return ref.watch(aiAssistantRepositoryProvider).analyzeBudget();
});

final remindersProvider = FutureProvider.autoDispose<List<Reminder>>((ref) {
  return ref.watch(aiAssistantRepositoryProvider).getReminders();
});
```

- [ ] **Step 3: analyze**
`export PATH="/opt/homebrew/bin:$PATH" && cd frontend && flutter analyze lib/features/ai_assistant/presentation/providers`
Expected: без ошибок.

- [ ] **Step 4: Commit**
```bash
git add frontend/lib/features/ai_assistant/presentation/providers
git commit -m "feat(ai-fe): чат передаёт историю; провайдеры анализа бюджета и напоминаний"
```

---

## Task F3: Маршрут /ai + вход из «Ещё» + экран с вкладками

**Files:**
- Modify `frontend/lib/app/router/app_router.dart`
- Modify `frontend/lib/features/more/presentation/pages/more_page.dart`
- Create `frontend/lib/features/ai_assistant/presentation/screens/ai_home_screen.dart`
- Test `frontend/test/features/ai_assistant/ai_home_screen_test.dart`

- [ ] **Step 1: ai_home_screen.dart** — контейнер с 3 вкладками (Чат = существующий `AiAssistantScreen`)
```dart
import 'package:flutter/material.dart';

import 'ai_assistant_screen.dart';
import 'budget_analysis_tab.dart';
import 'reminders_tab.dart';

class AiHomeScreen extends StatelessWidget {
  const AiHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ИИ-помощник'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Чат'),
            Tab(text: 'Анализ'),
            Tab(text: 'Напоминания'),
          ]),
        ),
        body: const TabBarView(children: [
          AiAssistantScreen(),
          BudgetAnalysisTab(),
          RemindersTab(),
        ]),
      ),
    );
  }
}
```
> `AiAssistantScreen` существует (экран чата+инсайтов). `BudgetAnalysisTab`/`RemindersTab` создаются в F4/F5 — для компиляции F3 сначала создай их пустыми заглушками-`Placeholder` (см. шаг 2), затем F4/F5 наполнят.

- [ ] **Step 2: временные заглушки вкладок** (чтобы F3 компилировался; F4/F5 заменят содержимым)
Create `frontend/lib/features/ai_assistant/presentation/screens/budget_analysis_tab.dart`:
```dart
import 'package:flutter/material.dart';
class BudgetAnalysisTab extends StatelessWidget {
  const BudgetAnalysisTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Анализ бюджета'));
}
```
Create `frontend/lib/features/ai_assistant/presentation/screens/reminders_tab.dart`:
```dart
import 'package:flutter/material.dart';
class RemindersTab extends StatelessWidget {
  const RemindersTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Напоминания'));
}
```

- [ ] **Step 3: app_router.dart** — top-level GoRoute `/ai` (как `family`/`groups`)
Импорт: `import '../../features/ai_assistant/presentation/screens/ai_home_screen.dart';`
После блока GoRoute для `admin` (перед `StatefulShellRoute`) добавить:
```dart
      GoRoute(
        path: AppRoutes.ai.path,
        name: AppRoutes.ai.name,
        pageBuilder: (ctx, state) =>
            fadeThroughPage(key: state.pageKey, child: const AiHomeScreen()),
      ),
```

- [ ] **Step 4: more_page.dart** — пункт входа в секции «Управление» (первым):
```dart
            InsetTile(
              title: 'ИИ-помощник',
              leading: const Icon(Icons.auto_awesome_rounded),
              onTap: () => context.push(AppRoutes.ai.path),
            ),
```

- [ ] **Step 5: Write the failing widget test** `ai_home_screen_test.dart`
```dart
import 'package:aifb/app/theme/app_theme.dart';
import 'package:aifb/features/ai_assistant/presentation/screens/ai_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AiHomeScreen shows three tabs', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(theme: AppTheme.light, home: const AiHomeScreen()),
    ));
    expect(find.text('Чат'), findsOneWidget);
    expect(find.text('Анализ'), findsOneWidget);
    expect(find.text('Напоминания'), findsOneWidget);
  });
}
```

- [ ] **Step 6: Run → fail then pass** (после реализации) + analyze
`export PATH="/opt/homebrew/bin:$PATH" && cd frontend && flutter test test/features/ai_assistant/ai_home_screen_test.dart`
> Тест рендерит `AiHomeScreen`; вкладка «Чат» (`AiAssistantScreen`) при первом кадре читает провайдеры — но `DefaultTabController` показывает только активную вкладку (Чат). Если `AiAssistantScreen` падает в тесте из-за сетевых провайдеров — обернуть проверку только в наличие табов достаточно (TabBarView лениво строит неактивные). Если активная вкладка «Чат» вызывает сеть — допустимо в тесте, т.к. провайдер вернёт loading-состояние (AsyncLoading), экран покажет индикатор; убедись, что нет throw. При необходимости — стартовая вкладка пустая; но обычно достаточно проверки табов.

- [ ] **Step 7: Commit**
```bash
git add frontend/lib/app/router/app_router.dart frontend/lib/features/more/presentation/pages/more_page.dart frontend/lib/features/ai_assistant/presentation/screens/ai_home_screen.dart frontend/lib/features/ai_assistant/presentation/screens/budget_analysis_tab.dart frontend/lib/features/ai_assistant/presentation/screens/reminders_tab.dart frontend/test/features/ai_assistant/ai_home_screen_test.dart
git commit -m "feat(ai-fe): маршрут /ai + вход из «Ещё» + экран с вкладками Чат/Анализ/Напоминания"
```

---

## Task F4: Вкладка «Анализ бюджета»

**Files:** Modify `frontend/lib/features/ai_assistant/presentation/screens/budget_analysis_tab.dart`

- [ ] **Step 1: Реализация вкладки** (читает `budgetAnalysisProvider`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ai_extra_providers.dart';

class BudgetAnalysisTab extends ConsumerWidget {
  const BudgetAnalysisTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(budgetAnalysisProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(budgetAnalysisProvider.future),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: [
          const SizedBox(height: 80),
          Center(child: Text('Не удалось получить анализ: $e')),
        ]),
        data: (a) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Анализ бюджета', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(a.analysis),
            const SizedBox(height: 20),
            if (a.tips.isNotEmpty) ...[
              Text('Советы', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...a.tips.map((t) => ListTile(
                    leading: const Icon(Icons.lightbulb_outline),
                    title: Text(t),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: analyze**
`export PATH="/opt/homebrew/bin:$PATH" && cd frontend && flutter analyze lib/features/ai_assistant/presentation/screens/budget_analysis_tab.dart`
Expected: без ошибок.

- [ ] **Step 3: Commit**
```bash
git add frontend/lib/features/ai_assistant/presentation/screens/budget_analysis_tab.dart
git commit -m "feat(ai-fe): вкладка «Анализ бюджета» (/ai/analyze-budget)"
```

---

## Task F5: Вкладка «Напоминания» (список + прогресс + форма)

**Files:** Modify `frontend/lib/features/ai_assistant/presentation/screens/reminders_tab.dart`

- [ ] **Step 1: Реализация вкладки** (список из `remindersProvider` + форма создания + удаление)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ai_dependency_provider.dart';
import '../providers/ai_extra_providers.dart';

class RemindersTab extends ConsumerWidget {
  const RemindersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(remindersProvider);
    return Scaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Пока нет напоминаний'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final r = items[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(r.eventName,
                                  style: Theme.of(context).textTheme.titleMedium)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await ref.read(aiAssistantRepositoryProvider).deleteReminder(r.id);
                                  ref.invalidate(remindersProvider);
                                },
                              ),
                            ],
                          ),
                          Text('Через ${r.daysUntil} дн. • откладывать ${r.monthlyNeeded.toStringAsFixed(0)}/мес'),
                          if (r.targetAmount != null) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(value: (r.progressPercent / 100).clamp(0, 1)),
                            const SizedBox(height: 4),
                            Text('${r.savedAmount.toStringAsFixed(0)} / ${r.targetAmount!.toStringAsFixed(0)}'),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    DateTime date = DateTime.now().add(const Duration(days: 90));
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Событие')),
              TextField(controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Сумма (необязательно)')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text('Дата: ${date.toIso8601String().split('T').first}')),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx, initialDate: date,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setState(() => date = picked);
                  },
                  child: const Text('Выбрать'),
                ),
              ]),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  await ref.read(aiAssistantRepositoryProvider).createReminder(
                        eventName: nameCtrl.text.trim(),
                        eventDate: date,
                        targetAmount: double.tryParse(targetCtrl.text),
                      );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                child: const Text('Добавить'),
              ),
            ],
          ),
        ),
      ),
    );
    if (created == true) ref.invalidate(remindersProvider);
  }
}
```

- [ ] **Step 2: analyze**
`export PATH="/opt/homebrew/bin:$PATH" && cd frontend && flutter analyze lib/features/ai_assistant/presentation/screens/reminders_tab.dart`
Expected: без ошибок (устранить любые предупреждения на новых строках).

- [ ] **Step 3: Commit**
```bash
git add frontend/lib/features/ai_assistant/presentation/screens/reminders_tab.dart
git commit -m "feat(ai-fe): вкладка «Напоминания» (список+прогресс+форма создания+удаление)"
```

---

## Task F6: Полная верификация + документация

**Files:** Modify `docs/DEPLOYMENT.md`

- [ ] **Step 1: Полный backend-прогон**
`cd backend && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew test`
Expected: BUILD SUCCESSFUL.

- [ ] **Step 2: Полный frontend-прогон**
`export PATH="/opt/homebrew/bin:$PATH" && cd frontend && flutter test`
Expected: All tests passed.

- [ ] **Step 3: Frontend analyze (без ошибок)**
`export PATH="/opt/homebrew/bin:$PATH" && cd frontend && flutter analyze 2>/dev/null | grep -cE "^\s+error"` → ожидается `0` (info-уровень предсуществующего стиля допустим).

- [ ] **Step 4: DEPLOYMENT.md — раздел ИИ-помощника**
Добавить раздел «## 10. ИИ-помощник (Claude API)»: переменные `ANTHROPIC_API_KEY`, `AI_DEV_MODE` (дефолт `true` — демо/тесты без ключа), `ANTHROPIC_MODEL` (дефолт `claude-sonnet-4-6`); модель меняется переменной; для прода `AI_DEV_MODE=false` + заданный `ANTHROPIC_API_KEY` (без ключа в реальном режиме приложение падает на старте — fail-fast); миграций теперь V1…V15. Также отметить: проактивная push-доставка напоминаний (90/30/7/1 дн.) отложена к этапу FCM — пока напоминания видны в приложении.

- [ ] **Step 5: Commit**
```bash
git add docs/DEPLOYMENT.md
git commit -m "docs(deploy): раздел ИИ-помощника (env Claude API, dev/prod) + число миграций"
```

---

## Definition of Done

- Backend-модуль `ai`: `/ai/chat`, `/ai/analyze-budget`, `/ai/insights`, `/ai/savings-plan`, CRUD `/ai/reminders` — под JWT; dev-режим даёт детерминированные ответы без сети, реальный Claude включается `AI_DEV_MODE=false` + `ANTHROPIC_API_KEY`.
- Миграция V15 `ai_reminders`; статус (daysUntil/monthlyNeeded/progress) считается на чтении.
- Frontend: скелет `ai_assistant` подключён к реальным эндпоинтам через аутентифицированный `dio`; маршрут `/ai` + вход из «Ещё»; вкладки Чат/Анализ/Напоминания (список+прогресс+форма).
- Полные наборы тестов (backend + frontend) зелёные; `flutter analyze` без ошибок.
- Env-переменные Claude задокументированы в `docs/DEPLOYMENT.md`.

## Out of scope (этап FCM, этап 5 ТЗ)

- Проактивная push-доставка напоминаний в 90/30/7/1 дней (cron + FCM + device-токены). `notify_days_before` хранится — доставку подключит FCM.
- Авто-обновление `saved_amount` из целей (goals).
- Полностью модельный JSON для инсайтов/плана (сейчас детерминированная арифметика + текст от модели в чате/анализе).
