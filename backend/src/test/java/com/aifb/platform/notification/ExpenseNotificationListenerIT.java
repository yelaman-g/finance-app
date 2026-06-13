package com.aifb.platform.notification;

import com.aifb.platform.common.domain.Scope;
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

class ExpenseNotificationListenerIT extends AbstractIntegrationTest {

    @Autowired TransactionService transactions;
    @Autowired CategoryService categoryService;
    @Autowired NotificationService notifications;
    @Autowired HouseholdService householdService;
    @Autowired PushSender pushSender;
    @Autowired TestAuth testAuth;

    private record Family(UUID owner, UUID member, String ownerTok, String memberTok) {}

    private Family family() {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser member = testAuth.createUser();
        String code = householdService.create(owner.id(), new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(member.id(), new JoinHouseholdRequest(code));
        String ownerTok = "tok-owner-" + owner.id();
        String memberTok = "tok-member-" + member.id();
        notifications.registerToken(owner.id(), ownerTok, DevicePlatform.ANDROID);
        notifications.registerToken(member.id(), memberTok, DevicePlatform.ANDROID);
        return new Family(owner.id(), member.id(), ownerTok, memberTok);
    }

    @Test
    void sharedExpenseNotifiesMembersExceptAuthor() {
        Family f = family();
        UUID cat = categoryService.list(f.owner(), CategoryType.EXPENSE, Scope.FAMILY).get(0).id();
        DevPushSender dev = (DevPushSender) pushSender;

        transactions.create(f.owner(), new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("2500.00"), "Кафе", LocalDate.now(), true));

        assertThat(dev.sent()).anyMatch(s -> s.token().equals(f.memberTok()));
        assertThat(dev.sent()).noneMatch(s -> s.token().equals(f.ownerTok()));
    }

    @Test
    void personalExpenseDoesNotNotify() {
        Family f = family();
        UUID cat = categoryService.list(f.owner(), CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
        DevPushSender dev = (DevPushSender) pushSender;
        int before = dev.sent().size();

        transactions.create(f.owner(), new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("500.00"), "личное", LocalDate.now(), false));

        assertThat(dev.sent().size()).isEqualTo(before);
    }

    @Test
    void familyIncomeDoesNotNotify() {
        Family f = family();
        UUID cat = categoryService.list(f.owner(), CategoryType.INCOME, Scope.FAMILY).get(0).id();
        DevPushSender dev = (DevPushSender) pushSender;
        int before = dev.sent().size();

        transactions.create(f.owner(), new CreateTransactionRequest(
                cat, CategoryType.INCOME, new BigDecimal("9000.00"), "премия", LocalDate.now(), true));

        assertThat(dev.sent().size()).isEqualTo(before);
    }
}
