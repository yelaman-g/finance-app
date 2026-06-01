package com.aifb.platform.finance.transaction;

import com.aifb.platform.common.api.PageResponse;
import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.finance.category.api.dto.CategoryResponse;
import com.aifb.platform.finance.category.api.dto.CreateCategoryRequest;
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
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class TransactionServiceIT extends AbstractIntegrationTest {

    @Autowired TransactionService service;
    @Autowired CategoryService categoryService;
    @Autowired TestAuth testAuth;

    private UUID expenseCategory(UUID userId) {
        return categoryService.list(userId, CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
    }

    @Test
    void createPersistsTransactionWithCategoryName() {
        UUID userId = testAuth.createUser().id();
        UUID categoryId = expenseCategory(userId);

        TransactionResponse created = service.create(userId, new CreateTransactionRequest(
                categoryId, CategoryType.EXPENSE, new BigDecimal("1500.00"),
                "Обед", LocalDate.now(), false));

        assertThat(created.id()).isNotNull();
        assertThat(created.amount()).isEqualByComparingTo("1500.00");
        assertThat(created.categoryName()).isNotBlank();
    }

    @Test
    void createRejectsTypeMismatchWithCategory() {
        UUID userId = testAuth.createUser().id();
        UUID expenseId = expenseCategory(userId);
        assertThatThrownBy(() -> service.create(userId, new CreateTransactionRequest(
                expenseId, CategoryType.INCOME, new BigDecimal("100.00"), null, LocalDate.now(), false)))
                .isInstanceOf(DomainException.class);
    }

    @Test
    void createRejectsCategoryOfAnotherUser() {
        UUID owner = testAuth.createUser().id();
        UUID other = testAuth.createUser().id();
        CategoryResponse ownCat = categoryService.create(owner,
                new CreateCategoryRequest("Личное", CategoryType.EXPENSE, null, null, false, null));
        assertThatThrownBy(() -> service.create(other, new CreateTransactionRequest(
                ownCat.id(), CategoryType.EXPENSE, new BigDecimal("100.00"), null, LocalDate.now(), false)))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void listIsScopedToUserAndFiltersByType() {
        UUID userId = testAuth.createUser().id();
        UUID other = testAuth.createUser().id();
        UUID expenseId = expenseCategory(userId);
        UUID incomeId = categoryService.list(userId, CategoryType.INCOME, Scope.PERSONAL).get(0).id();

        service.create(userId, new CreateTransactionRequest(
                expenseId, CategoryType.EXPENSE, new BigDecimal("100.00"), null, LocalDate.now(), false));
        service.create(userId, new CreateTransactionRequest(
                incomeId, CategoryType.INCOME, new BigDecimal("500.00"), null, LocalDate.now(), false));

        PageResponse<TransactionResponse> expenses =
                service.list(userId, null, null, CategoryType.EXPENSE, null, Scope.PERSONAL, 0, 20);
        assertThat(expenses.items()).hasSize(1);
        assertThat(expenses.items().get(0).type()).isEqualTo("EXPENSE");

        PageResponse<TransactionResponse> otherUser =
                service.list(other, null, null, null, null, Scope.PERSONAL, 0, 20);
        assertThat(otherUser.items()).isEmpty();
    }

    @Test
    void updateChangesAmountAndCategory() {
        UUID userId = testAuth.createUser().id();
        UUID expenseId = expenseCategory(userId);
        TransactionResponse created = service.create(userId, new CreateTransactionRequest(
                expenseId, CategoryType.EXPENSE, new BigDecimal("100.00"), null, LocalDate.now(), false));

        TransactionResponse updated = service.update(userId, created.id(),
                new com.aifb.platform.finance.transaction.api.dto.UpdateTransactionRequest(
                        expenseId, CategoryType.EXPENSE, new BigDecimal("250.50"),
                        "правка", LocalDate.now()));
        assertThat(updated.amount()).isEqualByComparingTo("250.50");
        assertThat(updated.note()).isEqualTo("правка");
    }

    @Test
    void deleteRemovesTransaction() {
        UUID userId = testAuth.createUser().id();
        UUID expenseId = expenseCategory(userId);
        TransactionResponse created = service.create(userId, new CreateTransactionRequest(
                expenseId, CategoryType.EXPENSE, new BigDecimal("100.00"), null, LocalDate.now(), false));
        service.delete(userId, created.id());
        assertThat(service.list(userId, null, null, null, null, Scope.PERSONAL, 0, 20).items()).isEmpty();
    }

    @Test
    void getOtherUsersTransactionNotFound() {
        UUID owner = testAuth.createUser().id();
        UUID other = testAuth.createUser().id();
        UUID expenseId = expenseCategory(owner);
        TransactionResponse created = service.create(owner, new CreateTransactionRequest(
                expenseId, CategoryType.EXPENSE, new BigDecimal("100.00"), null, LocalDate.now(), false));
        assertThatThrownBy(() -> service.get(other, created.id()))
                .isInstanceOf(NotFoundException.class);
    }
}
