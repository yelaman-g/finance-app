package com.aifb.platform.finance.transaction;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.finance.categorization.api.dto.CreateRuleRequest;
import com.aifb.platform.finance.categorization.service.CategorizationService;
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
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class AutoCategorizeIT extends AbstractIntegrationTest {

    @Autowired TransactionService transactionService;
    @Autowired CategorizationService categorizationService;
    @Autowired CategoryService categoryService;
    @Autowired TestAuth testAuth;

    @Test
    void personalTransactionWithoutCategoryResolvedByRule() {
        UUID userId = testAuth.createUser().id();
        UUID cat = categoryService.list(userId, CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
        categorizationService.create(userId, new CreateRuleRequest("magnum", cat));

        TransactionResponse tx = transactionService.create(userId, new CreateTransactionRequest(
                null, CategoryType.EXPENSE, new BigDecimal("100.00"), "Покупка MAGNUM", LocalDate.now(), false));
        assertThat(tx.categoryId()).isEqualTo(cat);
    }

    @Test
    void noRuleMatchWithoutCategoryRejected() {
        UUID userId = testAuth.createUser().id();
        assertThatThrownBy(() -> transactionService.create(userId, new CreateTransactionRequest(
                null, CategoryType.EXPENSE, new BigDecimal("100.00"), "Что-то", LocalDate.now(), false)))
                .isInstanceOf(DomainException.class);
    }

    @Test
    void sharedTransactionWithoutCategoryRejected() {
        UUID userId = testAuth.createUser().id();
        assertThatThrownBy(() -> transactionService.create(userId, new CreateTransactionRequest(
                null, CategoryType.EXPENSE, new BigDecimal("100.00"), "MAGNUM", LocalDate.now(), true)))
                .isInstanceOf(DomainException.class);
    }

    @Test
    void explicitCategoryNotOverriddenByRule() {
        UUID userId = testAuth.createUser().id();
        List<com.aifb.platform.finance.category.api.dto.CategoryResponse> cats =
                categoryService.list(userId, CategoryType.EXPENSE, Scope.PERSONAL);
        UUID ruleCat = cats.get(0).id();
        UUID chosenCat = cats.get(1).id();
        categorizationService.create(userId, new CreateRuleRequest("magnum", ruleCat));
        TransactionResponse tx = transactionService.create(userId, new CreateTransactionRequest(
                chosenCat, CategoryType.EXPENSE, new BigDecimal("100.00"), "MAGNUM", LocalDate.now(), false));
        assertThat(tx.categoryId()).isEqualTo(chosenCat);
    }
}
