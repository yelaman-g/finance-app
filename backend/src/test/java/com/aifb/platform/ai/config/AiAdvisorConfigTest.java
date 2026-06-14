package com.aifb.platform.ai.config;

import com.aifb.platform.ai.advisor.ClaudeFinanceAdvisor;
import com.aifb.platform.ai.advisor.DevFinanceAdvisor;
import com.aifb.platform.ai.advisor.FinanceAdvisor;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class AiAdvisorConfigTest {

    private final AiAdvisorConfig config = new AiAdvisorConfig();

    @Test
    void blankKeyFallsBackToDevAdvisor() {
        FinanceAdvisor advisor = config.claudeFinanceAdvisor("", "claude-sonnet-4-6", 2048);
        assertThat(advisor).isInstanceOf(DevFinanceAdvisor.class);
    }

    @Test
    void presentKeyUsesClaude() {
        FinanceAdvisor advisor = config.claudeFinanceAdvisor("sk-test-not-real", "claude-sonnet-4-6", 2048);
        assertThat(advisor).isInstanceOf(ClaudeFinanceAdvisor.class);
    }
}
