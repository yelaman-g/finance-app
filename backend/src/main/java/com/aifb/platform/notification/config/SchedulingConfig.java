package com.aifb.platform.notification.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

@Configuration
@EnableScheduling
public class SchedulingConfig {

    @Bean
    public java.time.Clock clock() {
        return java.time.Clock.systemDefaultZone();
    }
}
