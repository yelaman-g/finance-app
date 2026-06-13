package com.aifb.platform.notification.config;

import com.aifb.platform.notification.service.DevPushSender;
import com.aifb.platform.notification.service.FcmPushSender;
import com.aifb.platform.notification.service.PushSender;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class FcmConfig {

    @Bean
    @ConditionalOnProperty(prefix = "aifb.fcm", name = "dev-mode", havingValue = "true", matchIfMissing = true)
    public PushSender devPushSender() {
        return new DevPushSender();
    }

    @Bean
    @ConditionalOnProperty(prefix = "aifb.fcm", name = "dev-mode", havingValue = "false")
    public PushSender fcmPushSender(@Value("${aifb.fcm.service-account-json:}") String serviceAccountJson) {
        return new FcmPushSender(serviceAccountJson);
    }
}
