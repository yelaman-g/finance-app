package com.aifb.platform.notification;

import com.aifb.platform.notification.domain.DevicePlatform;
import com.aifb.platform.notification.domain.DeviceToken;
import com.aifb.platform.notification.domain.NotificationSource;
import com.aifb.platform.notification.repository.DeviceTokenRepository;
import com.aifb.platform.notification.service.DevPushSender;
import com.aifb.platform.notification.service.NotificationCandidate;
import com.aifb.platform.notification.service.NotificationService;
import com.aifb.platform.notification.service.PushSender;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

class NotificationServiceIT extends AbstractIntegrationTest {

    @Autowired NotificationService service;
    @Autowired DeviceTokenRepository tokens;
    @Autowired PushSender pushSender;   // в тестах активен DevPushSender (dev-mode по умолчанию)
    @Autowired TestAuth testAuth;

    @Test
    void deliverSendsOnceThenDedups() {
        TestAuth.AuthedUser u = testAuth.createUser();
        service.registerToken(u.id(), "tok-x", DevicePlatform.ANDROID);
        DevPushSender dev = (DevPushSender) pushSender;
        int before = dev.sent().size();

        NotificationCandidate c = new NotificationCandidate(NotificationSource.REMINDER,
                u.id(), u.id(), null, LocalDate.parse("2026-08-01"), 7, "Скоро", "Текст");
        service.deliver(c);
        service.deliver(c);  // повтор — должен быть пропущен дедупом

        assertThat(dev.sent().size() - before).isEqualTo(1);
    }

    @Test
    void registerTokenUpsertsByToken() {
        TestAuth.AuthedUser u = testAuth.createUser();
        service.registerToken(u.id(), "tok-dup", DevicePlatform.ANDROID);
        service.registerToken(u.id(), "tok-dup", DevicePlatform.IOS);
        assertThat(tokens.findByToken("tok-dup")).isPresent();
        assertThat(tokens.findByUserIdIn(java.util.List.of(u.id()))).hasSize(1);
    }
}
