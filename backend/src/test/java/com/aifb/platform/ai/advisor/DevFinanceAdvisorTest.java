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
        assertThat(reply.content()).contains("Еда");
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
        assertThat(plan.monthlyAmount()).isGreaterThan(BigDecimal.ZERO);
    }

    @Test
    void analyzeReturnsTextAndTips() {
        var a = advisor.analyzeBudget(ctx());
        assertThat(a.analysis()).isNotBlank();
        assertThat(a.tips()).isNotNull();
    }
}
