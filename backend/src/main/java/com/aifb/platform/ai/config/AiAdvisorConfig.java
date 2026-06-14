package com.aifb.platform.ai.config;

import com.aifb.platform.ai.advisor.ClaudeFinanceAdvisor;
import com.aifb.platform.ai.advisor.DevFinanceAdvisor;
import com.aifb.platform.ai.advisor.FinanceAdvisor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AiAdvisorConfig {

    private static final Logger log = LoggerFactory.getLogger(AiAdvisorConfig.class);

    @Bean
    @ConditionalOnProperty(prefix = "aifb.ai", name = "dev-mode", havingValue = "true", matchIfMissing = true)
    public FinanceAdvisor devFinanceAdvisor() {
        return new DevFinanceAdvisor();
    }

    @Bean
    @ConditionalOnProperty(prefix = "aifb.ai", name = "dev-mode", havingValue = "false")
    public FinanceAdvisor claudeFinanceAdvisor(
            @Value("${aifb.ai.api-key:}") String apiKey,
            @Value("${aifb.ai.model:claude-sonnet-4-6}") String model,
            @Value("${aifb.ai.max-tokens:2048}") long maxTokens) {
        if (apiKey == null || apiKey.isBlank()) {
            // ИИ — некритичный модуль: не валим всё приложение из-за пустого ключа,
            // а логируем и откатываемся к детерминированному dev-помощнику.
            log.error("aifb.ai.dev-mode=false, но ANTHROPIC_API_KEY пуст — откат к dev-режиму "
                    + "ИИ-помощника (детерминированные ответы). Задайте ANTHROPIC_API_KEY для реального Claude.");
            return new DevFinanceAdvisor();
        }
        return new ClaudeFinanceAdvisor(apiKey, model, maxTokens);
    }
}
