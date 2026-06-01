package com.aifb.platform.finance.statistics;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.finance.statistics.api.dto.CategoryBreakdownResponse;
import com.aifb.platform.finance.statistics.api.dto.SummaryResponse;
import com.aifb.platform.finance.statistics.api.dto.TrendPointResponse;
import com.aifb.platform.finance.statistics.service.StatisticsService;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
import com.aifb.platform.finance.transaction.service.TransactionService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class StatisticsServiceIT extends AbstractIntegrationTest {

    @Autowired StatisticsService service;
    @Autowired TransactionService transactionService;
    @Autowired CategoryService categoryService;
    @Autowired TestAuth testAuth;

    private void tx(UUID userId, UUID categoryId, CategoryType type, String amount, LocalDate when) {
        transactionService.create(userId, new CreateTransactionRequest(
                categoryId, type, new BigDecimal(amount), null, when, false));
    }

    @Test
    void summaryComputesIncomeExpenseNet() {
        UUID userId = testAuth.createUser().id();
        UUID expenseId = categoryService.list(userId, CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
        UUID incomeId = categoryService.list(userId, CategoryType.INCOME, Scope.PERSONAL).get(0).id();

        tx(userId, incomeId, CategoryType.INCOME, "1000.00", LocalDate.now());
        tx(userId, expenseId, CategoryType.EXPENSE, "300.00", LocalDate.now());
        tx(userId, expenseId, CategoryType.EXPENSE, "200.00", LocalDate.now());

        SummaryResponse summary = service.summary(userId, null, null);
        assertThat(summary.income()).isEqualByComparingTo("1000.00");
        assertThat(summary.expense()).isEqualByComparingTo("500.00");
        assertThat(summary.net()).isEqualByComparingTo("500.00");
    }

    @Test
    void summaryIsEmptyForNewUser() {
        UUID userId = testAuth.createUser().id();
        SummaryResponse summary = service.summary(userId, null, null);
        assertThat(summary.income()).isEqualByComparingTo("0");
        assertThat(summary.expense()).isEqualByComparingTo("0");
        assertThat(summary.net()).isEqualByComparingTo("0");
    }

    @Test
    void byCategoryReturnsTotalsAndPercentages() {
        UUID userId = testAuth.createUser().id();
        List<com.aifb.platform.finance.category.api.dto.CategoryResponse> cats =
                categoryService.list(userId, CategoryType.EXPENSE, Scope.PERSONAL);
        UUID c1 = cats.get(0).id();
        UUID c2 = cats.get(1).id();

        tx(userId, c1, CategoryType.EXPENSE, "750.00", LocalDate.now());
        tx(userId, c2, CategoryType.EXPENSE, "250.00", LocalDate.now());

        List<CategoryBreakdownResponse> breakdown =
                service.byCategory(userId, CategoryType.EXPENSE, null, null);
        assertThat(breakdown).hasSize(2);
        assertThat(breakdown.get(0).total()).isEqualByComparingTo("750.00");
        assertThat(breakdown.get(0).percentage()).isEqualTo(75.0);
        assertThat(breakdown.get(0).name()).isNotBlank();
    }

    @Test
    void trendGroupsByMonth() {
        UUID userId = testAuth.createUser().id();
        UUID incomeId = categoryService.list(userId, CategoryType.INCOME, Scope.PERSONAL).get(0).id();
        UUID expenseId = categoryService.list(userId, CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();

        tx(userId, incomeId, CategoryType.INCOME, "1000.00", LocalDate.now());
        tx(userId, expenseId, CategoryType.EXPENSE, "400.00", LocalDate.now());

        List<TrendPointResponse> trend = service.trend(userId, null, null);
        assertThat(trend).isNotEmpty();
        TrendPointResponse current = trend.get(trend.size() - 1);
        assertThat(current.month()).matches("\\d{4}-\\d{2}");
        assertThat(current.income()).isEqualByComparingTo("1000.00");
        assertThat(current.expense()).isEqualByComparingTo("400.00");
    }
}
