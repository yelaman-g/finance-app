package com.aifb.platform.ai;

import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MvcResult;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AiReminderApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired ObjectMapper objectMapper;

    @Test
    void createListDeleteReminderWithStatus() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();

        MvcResult created = mockMvc.perform(post("/api/v1/ai/reminders")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"eventName\":\"День рождения\",\"eventDate\":\"%s\",\"targetAmount\":30000,\"savedAmount\":10000}"
                                .formatted(java.time.LocalDate.now().plusMonths(3))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.eventName").value("День рождения"))
                .andExpect(jsonPath("$.data.monthlyNeeded").isNumber())
                .andExpect(jsonPath("$.data.progressPercent").isNumber())
                .andReturn();
        String id = objectMapper.readTree(created.getResponse().getContentAsString())
                .path("data").path("id").asText();

        mockMvc.perform(get("/api/v1/ai/reminders")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].eventName").value("День рождения"));

        mockMvc.perform(delete("/api/v1/ai/reminders/" + id)
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk());
    }

    @Test
    void remindersRequireAuth() throws Exception {
        mockMvc.perform(get("/api/v1/ai/reminders")).andExpect(status().isUnauthorized());
    }
}
