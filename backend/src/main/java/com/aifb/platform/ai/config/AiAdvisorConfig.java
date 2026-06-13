package com.aifb.platform.ai.config;

import com.aifb.platform.ai.advisor.ClaudeFinanceAdvisor;
import com.aifb.platform.ai.advisor.DevFinanceAdvisor;
import com.aifb.platform.ai.advisor.FinanceAdvisor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AiAdvisorConfig {

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
            throw new IllegalStateException("ANTHROPIC_API_KEY must be set when aifb.ai.dev-mode=false");
        }
        return new ClaudeFinanceAdvisor(apiKey, model, maxTokens);
    }
}
