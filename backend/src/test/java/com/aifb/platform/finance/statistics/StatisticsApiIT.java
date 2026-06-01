package com.aifb.platform.finance.statistics;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
import com.aifb.platform.finance.transaction.service.TransactionService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class StatisticsApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired CategoryService categoryService;
    @Autowired TransactionService transactionService;

    @Test
    void summaryEndpointReturnsTotals() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        UUID incomeId = categoryService.list(user.id(), CategoryType.INCOME, Scope.PERSONAL).get(0).id();
        transactionService.create(user.id(), new CreateTransactionRequest(
                incomeId, CategoryType.INCOME, new BigDecimal("900.00"), null, LocalDate.now(), false));

        mockMvc.perform(get("/api/v1/statistics/summary")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.income").value(900.00))
                .andExpect(jsonPath("$.data.net").value(900.00));
    }

    @Test
    void byCategoryEndpointReturnsArray() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        UUID expenseId = categoryService.list(user.id(), CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
        transactionService.create(user.id(), new CreateTransactionRequest(
                expenseId, CategoryType.EXPENSE, new BigDecimal("123.00"), null, LocalDate.now(), false));

        mockMvc.perform(get("/api/v1/statistics/by-category")
                        .param("type", "EXPENSE")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].total").value(123.00))
                .andExpect(jsonPath("$.data[0].percentage").value(100.0));
    }

    @Test
    void statisticsRequireAuth() throws Exception {
        mockMvc.perform(get("/api/v1/statistics/summary"))
                .andExpect(status().isUnauthorized());
    }
}
