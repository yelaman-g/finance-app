package com.aifb.platform.notification;

import com.aifb.platform.notification.service.DevPushSender;
import com.aifb.platform.notification.service.PushResult;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class DevPushSenderTest {

    @Test
    void recordsSendAndReturnsAccepted() {
        DevPushSender sender = new DevPushSender();
        PushResult r = sender.send("tok-1", "Заголовок", "Текст", Map.of("type", "EVENT"));
        assertThat(r.accepted()).isTrue();
        assertThat(r.tokenInvalid()).isFalse();
        assertThat(sender.sent()).hasSize(1);
        assertThat(sender.sent().get(0).title()).isEqualTo("Заголовок");
    }
}
