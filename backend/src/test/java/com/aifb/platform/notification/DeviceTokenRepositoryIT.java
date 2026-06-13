package com.aifb.platform.notification;

import com.aifb.platform.notification.domain.DevicePlatform;
import com.aifb.platform.notification.domain.DeviceToken;
import com.aifb.platform.notification.domain.NotificationSource;
import com.aifb.platform.notification.domain.SentNotification;
import com.aifb.platform.notification.repository.DeviceTokenRepository;
import com.aifb.platform.notification.repository.SentNotificationRepository;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class DeviceTokenRepositoryIT extends AbstractIntegrationTest {

    @Autowired DeviceTokenRepository tokens;
    @Autowired SentNotificationRepository sent;
    @Autowired TestAuth testAuth;

    @Test
    void savesAndFindsTokenByValue() {
        TestAuth.AuthedUser u = testAuth.createUser();
        tokens.saveAndFlush(new DeviceToken(u.id(), "tok-abc", DevicePlatform.ANDROID));
        assertThat(tokens.findByToken("tok-abc")).isPresent();
        assertThat(tokens.findByUserIdIn(List.of(u.id()))).hasSize(1);
    }

    @Test
    void sentNotificationDedupKeyWorks() {
        TestAuth.AuthedUser u = testAuth.createUser();
        sent.saveAndFlush(new SentNotification(u.id(), NotificationSource.REMINDER,
                u.id(), LocalDate.parse("2026-07-01"), 7));
        boolean exists = sent.existsBySourceTypeAndSourceIdAndOccurrenceDateAndThresholdDay(
                NotificationSource.REMINDER, u.id(), LocalDate.parse("2026-07-01"), 7);
        assertThat(exists).isTrue();
    }
}
