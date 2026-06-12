package com.aifb.platform.config;

import com.aifb.platform.auth.service.google.DevGoogleTokenVerifier;
import com.aifb.platform.auth.service.google.GoogleTokenVerifier;
import com.aifb.platform.auth.service.google.RealGoogleTokenVerifier;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GoogleAuthConfig {

    @Bean
    @ConditionalOnProperty(prefix = "aifb.google", name = "dev-mode", havingValue = "true")
    public GoogleTokenVerifier devGoogleTokenVerifier(ObjectMapper objectMapper) {
        return new DevGoogleTokenVerifier(objectMapper);
    }

    @Bean
    @ConditionalOnProperty(prefix = "aifb.google", name = "dev-mode", havingValue = "false")
    public GoogleTokenVerifier realGoogleTokenVerifier(@Value("${aifb.google.client-id:}") String clientId) {
        return new RealGoogleTokenVerifier(clientId);
    }
}
