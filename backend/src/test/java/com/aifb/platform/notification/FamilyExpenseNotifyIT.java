package com.aifb.platform.notification;

import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.service.HouseholdContextService;
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
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class FamilyExpenseNotifyIT extends AbstractIntegrationTest {

    @Autowired NotificationService notifications;
    @Autowired HouseholdService householdService;
    @Autowired HouseholdContextService householdContext;
    @Autowired PushSender pushSender;
    @Autowired TestAuth testAuth;

    @Test
    void notifiesMembersExceptAuthor() {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser member = testAuth.createUser();
        String code = householdService.create(owner.id(), new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(member.id(), new JoinHouseholdRequest(code));
        UUID householdId = householdContext.membershipOrNull(owner.id()).householdId();

        String ownerTok = "tok-owner-" + owner.id();
        String memberTok = "tok-member-" + member.id();
        notifications.registerToken(owner.id(), ownerTok, DevicePlatform.ANDROID);
        notifications.registerToken(member.id(), memberTok, DevicePlatform.ANDROID);

        DevPushSender dev = (DevPushSender) pushSender;
        notifications.notifyFamilyExpense(householdId, owner.id(), new BigDecimal("1500.00"), "Продукты");

        assertThat(dev.sent()).anyMatch(s -> s.token().equals(memberTok));
        assertThat(dev.sent()).noneMatch(s -> s.token().equals(ownerTok));
    }

    @Test
    void noRecipientsNoSend() {
        TestAuth.AuthedUser solo = testAuth.createUser();
        String code = householdService.create(solo.id(), new CreateHouseholdRequest("Одиночка")).inviteCode();
        UUID householdId = householdContext.membershipOrNull(solo.id()).householdId();
        String tok = "tok-solo-" + solo.id();
        notifications.registerToken(solo.id(), tok, DevicePlatform.ANDROID);

        DevPushSender dev = (DevPushSender) pushSender;
        // автор — единственный член семьи → после исключения автора получателей нет
        notifications.notifyFamilyExpense(householdId, solo.id(), new BigDecimal("100"), null);

        assertThat(dev.sent()).noneMatch(s -> s.token().equals(tok));
    }
}
