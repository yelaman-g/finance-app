package com.aifb.platform.finance.transaction;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.finance.budget.api.dto.CreateBudgetRequest;
import com.aifb.platform.finance.budget.domain.BudgetTargetType;
import com.aifb.platform.finance.budget.service.BudgetService;
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

class BudgetWarningIT extends AbstractIntegrationTest {

    @Autowired TransactionService transactionService;
    @Autowired BudgetService budgetService;
    @Autowired CategoryService categoryService;
    @Autowired TestAuth testAuth;

    @Test
    void exceedingBudgetReturnsWarningOnCreate() {
        UUID userId = testAuth.createUser().id();
        UUID cat = categoryService.list(userId, CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
        budgetService.create(userId, new CreateBudgetRequest(
                BudgetTargetType.CATEGORY, cat, null, new BigDecimal("100.00"), false));

        TransactionResponse tx = transactionService.create(userId, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("150.00"), null, LocalDate.now(), false));
        assertThat(tx.budgetWarnings()).isNotNull().hasSize(1);
        assertThat(tx.budgetWarnings().get(0).status()).isEqualTo("EXCEEDED");
    }

    @Test
    void withinBudgetNoWarning() {
        UUID userId = testAuth.createUser().id();
        UUID cat = categoryService.list(userId, CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
        budgetService.create(userId, new CreateBudgetRequest(
                BudgetTargetType.CATEGORY, cat, null, new BigDecimal("1000.00"), false));
        TransactionResponse tx = transactionService.create(userId, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("10.00"), null, LocalDate.now(), false));
        assertThat(tx.budgetWarnings()).isNull();
    }
}
