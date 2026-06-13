package com.aifb.platform.ai;

import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AiApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;

    @Test
    void chatRequiresAuth() throws Exception {
        mockMvc.perform(post("/api/v1/ai/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"messages\":[{\"role\":\"user\",\"content\":\"привет\"}]}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void chatReturnsAiMessage() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        mockMvc.perform(post("/api/v1/ai/chat")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"messages\":[{\"role\":\"user\",\"content\":\"Где трачу больше всего?\"}]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.role").value("ai"))
                .andExpect(jsonPath("$.data.content").isNotEmpty());
    }

    @Test
    void insightsReturnsList() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        mockMvc.perform(get("/api/v1/ai/insights")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray());
    }

    @Test
    void analyzeBudgetReturnsAnalysis() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        mockMvc.perform(post("/api/v1/ai/analyze-budget")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.analysis").isNotEmpty());
    }

    @Test
    void savingsPlanComputesMonthly() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        mockMvc.perform(post("/api/v1/ai/savings-plan")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"eventName\":\"Подарок\",\"eventDate\":\"%s\",\"targetAmount\":150000,\"savedAmount\":30000}"
                                .formatted(java.time.LocalDate.now().plusMonths(4))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.monthsRemaining").isNumber())
                .andExpect(jsonPath("$.data.monthlyAmount").isNumber());
    }
}
