package com.aifb.platform.finance.budget;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.finance.budget.api.dto.BudgetResponse;
import com.aifb.platform.finance.budget.api.dto.CreateBudgetRequest;
import com.aifb.platform.finance.budget.domain.BudgetTargetType;
import com.aifb.platform.finance.budget.service.BudgetService;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
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

class BudgetServiceIT extends AbstractIntegrationTest {

    @Autowired BudgetService service;
    @Autowired CategoryService categoryService;
    @Autowired TransactionService transactionService;
    @Autowired TestAuth testAuth;

    private UUID expenseCat(UUID userId) {
        return categoryService.list(userId, CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
    }

    @Test
    void createCategoryBudgetAndComputeSpentStatus() {
        UUID userId = testAuth.createUser().id();
        UUID cat = expenseCat(userId);
        BudgetResponse b = service.create(userId, new CreateBudgetRequest(
                BudgetTargetType.CATEGORY, cat, null, new BigDecimal("1000.00"), false));
        assertThat(b.spent()).isEqualByComparingTo("0");
        assertThat(b.status()).isEqualTo("OK");

        transactionService.create(userId, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("850.00"), null, LocalDate.now(), false));
        BudgetResponse after = service.list(userId, Scope.PERSONAL).stream()
                .filter(x -> x.id().equals(b.id())).findFirst().orElseThrow();
        assertThat(after.spent()).isEqualByComparingTo("850.00");
        assertThat(after.percentage()).isEqualTo(85.0);
        assertThat(after.status()).isEqualTo("WARNING");
    }

    @Test
    void exceededStatusOverLimit() {
        UUID userId = testAuth.createUser().id();
        UUID cat = expenseCat(userId);
        BudgetResponse b = service.create(userId, new CreateBudgetRequest(
                BudgetTargetType.CATEGORY, cat, null, new BigDecimal("100.00"), false));
        transactionService.create(userId, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("150.00"), null, LocalDate.now(), false));
        BudgetResponse after = service.list(userId, Scope.PERSONAL).stream()
                .filter(x -> x.id().equals(b.id())).findFirst().orElseThrow();
        assertThat(after.status()).isEqualTo("EXCEEDED");
    }

    @Test
    void duplicateBudgetForCategoryConflicts() {
        UUID userId = testAuth.createUser().id();
        UUID cat = expenseCat(userId);
        service.create(userId, new CreateBudgetRequest(
                BudgetTargetType.CATEGORY, cat, null, new BigDecimal("100.00"), false));
        assertThatThrownBy(() -> service.create(userId, new CreateBudgetRequest(
                BudgetTargetType.CATEGORY, cat, null, new BigDecimal("200.00"), false)))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void incomeCategoryRejected() {
        UUID userId = testAuth.createUser().id();
        UUID incomeCat = categoryService.list(userId, CategoryType.INCOME, Scope.PERSONAL).get(0).id();
        assertThatThrownBy(() -> service.create(userId, new CreateBudgetRequest(
                BudgetTargetType.CATEGORY, incomeCat, null, new BigDecimal("100.00"), false)))
                .isInstanceOf(DomainException.class);
    }

    @Test
    void deleteRemovesBudget() {
        UUID userId = testAuth.createUser().id();
        UUID cat = expenseCat(userId);
        BudgetResponse b = service.create(userId, new CreateBudgetRequest(
                BudgetTargetType.CATEGORY, cat, null, new BigDecimal("100.00"), false));
        service.delete(userId, b.id());
        assertThat(service.list(userId, Scope.PERSONAL)).noneMatch(x -> x.id().equals(b.id()));
    }
}
