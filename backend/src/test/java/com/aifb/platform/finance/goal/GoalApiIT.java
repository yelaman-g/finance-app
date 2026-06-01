package com.aifb.platform.finance.goal;

import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MvcResult;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class GoalApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired ObjectMapper objectMapper;

    @Test
    void createGoalAddContributionAndReadProgress() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();

        MvcResult created = mockMvc.perform(post("/api/v1/goals")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Подушка","targetAmount":1000.00,"icon":"savings","color":"#00AA66"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("ACTIVE"))
                .andExpect(jsonPath("$.data.savedAmount").value(0))
                .andReturn();

        JsonNode body = objectMapper.readTree(created.getResponse().getContentAsString());
        String goalId = body.path("data").path("id").asText();

        mockMvc.perform(post("/api/v1/goals/" + goalId + "/contributions")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"amount":1000.00,"note":"закрыли","contributedOn":"%s"}
                                """.formatted(java.time.LocalDate.now())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.amount").value(1000.00));

        mockMvc.perform(get("/api/v1/goals/" + goalId)
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.savedAmount").value(1000.00))
                .andExpect(jsonPath("$.data.status").value("COMPLETED"));
    }

    @Test
    void listGoalsRequiresAuth() throws Exception {
        mockMvc.perform(get("/api/v1/goals"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void createRejectsNonPositiveTarget() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        mockMvc.perform(post("/api/v1/goals")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Bad","targetAmount":0}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("VALIDATION_FAILED"));
    }
}
