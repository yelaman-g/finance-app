package com.aifb.platform.finance.transaction;

import com.aifb.platform.common.api.PageResponse;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
import com.aifb.platform.finance.transaction.api.dto.TransactionResponse;
import com.aifb.platform.finance.transaction.service.TransactionService;
import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.domain.HouseholdRole;
import com.aifb.platform.household.service.HouseholdService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class TransactionScopeIT extends AbstractIntegrationTest {

    @Autowired TransactionService service;
    @Autowired CategoryService categoryService;
    @Autowired HouseholdService householdService;
    @Autowired TestAuth testAuth;

    private UUID familyExpenseCat(UUID userId) {
        return categoryService.list(userId, CategoryType.EXPENSE, Scope.FAMILY).get(0).id();
    }

    @Test
    void sharedTransactionVisibleToFamilyWithAuthor() {
        UUID owner = testAuth.createUser().id();
        UUID member = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(member, new JoinHouseholdRequest(code));
        UUID cat = familyExpenseCat(owner);

        TransactionResponse tx = service.create(member, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("100.00"), "общая", LocalDate.now(), true));
        assertThat(tx.shared()).isTrue();
        assertThat(tx.authorId()).isEqualTo(member);

        PageResponse<TransactionResponse> fam =
                service.list(owner, null, null, null, null, Scope.FAMILY, 0, 20);
        assertThat(fam.items()).anyMatch(t -> t.id().equals(tx.id()));
        assertThat(service.list(member, null, null, null, null, Scope.PERSONAL, 0, 20).items())
                .noneMatch(t -> t.id().equals(tx.id()));
    }

    @Test
    void childCanCreateSharedTransaction() {
        UUID owner = testAuth.createUser().id();
        UUID child = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(child, new JoinHouseholdRequest(code));
        householdService.changeRole(owner, child, HouseholdRole.CHILD);
        UUID cat = familyExpenseCat(child);

        TransactionResponse tx = service.create(child, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("50.00"), null, LocalDate.now(), true));
        assertThat(tx.authorId()).isEqualTo(child);
    }

    @Test
    void childCannotDeleteOthersSharedTransaction() {
        UUID owner = testAuth.createUser().id();
        UUID child = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(child, new JoinHouseholdRequest(code));
        householdService.changeRole(owner, child, HouseholdRole.CHILD);
        UUID cat = familyExpenseCat(owner);

        TransactionResponse ownerTx = service.create(owner, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("100.00"), null, LocalDate.now(), true));
        assertThatThrownBy(() -> service.delete(child, ownerTx.id()))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void adultCanDeleteOthersSharedTransaction() {
        UUID owner = testAuth.createUser().id();
        UUID adult = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(adult, new JoinHouseholdRequest(code));
        UUID cat = familyExpenseCat(owner);

        TransactionResponse ownerTx = service.create(owner, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("100.00"), null, LocalDate.now(), true));
        service.delete(adult, ownerTx.id());
        assertThat(service.list(owner, null, null, null, null, Scope.FAMILY, 0, 20).items())
                .noneMatch(t -> t.id().equals(ownerTx.id()));
    }

    @Test
    void guestCannotCreateSharedTransaction() {
        UUID owner = testAuth.createUser().id();
        UUID member = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(member, new JoinHouseholdRequest(code));
        householdService.changeRole(owner, member, HouseholdRole.GUEST);
        UUID cat = familyExpenseCat(owner);

        assertThatThrownBy(() -> service.create(member, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("100.00"), null, LocalDate.now(), true)))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void guestCanViewFamilyTransactions() {
        UUID owner = testAuth.createUser().id();
        UUID guest = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(guest, new JoinHouseholdRequest(code));
        householdService.changeRole(owner, guest, HouseholdRole.GUEST);
        UUID cat = familyExpenseCat(owner);

        TransactionResponse ownerTx = service.create(owner, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("200.00"), null, LocalDate.now(), true));

        PageResponse<TransactionResponse> fam =
                service.list(guest, null, null, null, null, Scope.FAMILY, 0, 20);
        assertThat(fam.items()).anyMatch(t -> t.id().equals(ownerTx.id()));
    }
}
