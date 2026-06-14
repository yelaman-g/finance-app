package com.aifb.platform.finance.budget;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.finance.budget.api.dto.CreateBudgetRequest;
import com.aifb.platform.finance.budget.domain.BudgetTargetType;
import com.aifb.platform.finance.budget.service.BudgetService;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
import com.aifb.platform.finance.transaction.service.TransactionService;
import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.service.HouseholdService;
import com.aifb.platform.notification.domain.DevicePlatform;
import com.aifb.platform.notification.service.DevPushSender;
import com.aifb.platform.notification.service.NotificationService;
import com.aifb.platform.notification.service.PushSender;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class BudgetAlertIT extends AbstractIntegrationTest {

    @Autowired BudgetService budgetService;
    @Autowired TransactionService transactions;
    @Autowired CategoryService categoryService;
    @Autowired NotificationService notifications;
    @Autowired HouseholdService householdService;
    @Autowired PushSender pushSender;
    @Autowired TestAuth testAuth;

    /** Считает ТОЛЬКО budget-уведомления (по заголовку), отделяя их от push о семейном расходе. */
    private long budgetPushesTo(String token) {
        return ((DevPushSender) pushSender).sent().stream()
                .filter(s -> s.token().equals(token) && s.title().equals("Лимит почти исчерпан"))
                .count();
    }

    @Test
    void personalLimitThresholdPushesOnceThenDedups() {
        TestAuth.AuthedUser u = testAuth.createUser();
        String tok = "tok-budget-" + u.id();
        notifications.registerToken(u.id(), tok, DevicePlatform.ANDROID);
        UUID cat = categoryService.list(u.id(), CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
        budgetService.create(u.id(), new CreateBudgetRequest(
                BudgetTargetType.CATEGORY, cat, null, new BigDecimal("1000.00"), false, 50));

        transactions.create(u.id(), new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("600.00"), "трата1", LocalDate.now(), false));
        assertThat(budgetPushesTo(tok)).isEqualTo(1);

        transactions.create(u.id(), new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("100.00"), "трата2", LocalDate.now(), false));
        assertThat(budgetPushesTo(tok)).isEqualTo(1); // дедуп: раз в месяц на лимит
    }

    @Test
    void belowThresholdNoPush() {
        TestAuth.AuthedUser u = testAuth.createUser();
        String tok = "tok-budget-low-" + u.id();
        notifications.registerToken(u.id(), tok, DevicePlatform.ANDROID);
        UUID cat = categoryService.list(u.id(), CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
        budgetService.create(u.id(), new CreateBudgetRequest(
                BudgetTargetType.CATEGORY, cat, null, new BigDecimal("1000.00"), false, 80));

        transactions.create(u.id(), new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("300.00"), "мало", LocalDate.now(), false));
        assertThat(budgetPushesTo(tok)).isZero();
    }

    @Test
    void familyLimitNotifiesAllMembers() {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser member = testAuth.createUser();
        String code = householdService.create(owner.id(), new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(member.id(), new JoinHouseholdRequest(code));
        String ownerTok = "tok-fb-owner-" + owner.id();
        String memberTok = "tok-fb-member-" + member.id();
        notifications.registerToken(owner.id(), ownerTok, DevicePlatform.ANDROID);
        notifications.registerToken(member.id(), memberTok, DevicePlatform.ANDROID);
        UUID cat = categoryService.list(owner.id(), CategoryType.EXPENSE, Scope.FAMILY).get(0).id();
        budgetService.create(owner.id(), new CreateBudgetRequest(
                BudgetTargetType.CATEGORY, cat, null, new BigDecimal("1000.00"), true, 50));

        transactions.create(owner.id(), new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("700.00"), "семейная", LocalDate.now(), true));

        assertThat(budgetPushesTo(ownerTok)).isEqualTo(1);
        assertThat(budgetPushesTo(memberTok)).isEqualTo(1);
    }
}
