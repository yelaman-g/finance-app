package com.aifb.platform.event;

import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MvcResult;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class EventApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired ObjectMapper objectMapper;

    @Test
    void eventsRequireAuth() throws Exception {
        mockMvc.perform(get("/api/v1/events?from=2026-06-01&to=2026-06-30"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void createWeeklyEventExpandsAcrossMonth() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        mockMvc.perform(post("/api/v1/events")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Тренировка\",\"startDate\":\"2026-06-01\",\"allDay\":true,\"recurFreq\":\"WEEKLY\"}"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/v1/events?from=2026-06-01&to=2026-06-30")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(5))
                .andExpect(jsonPath("$.data[0].recurring").value(true));
    }

    @Test
    void oneOffEventWithBudgetCreatesLinkedReminder() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        MvcResult created = mockMvc.perform(post("/api/v1/events")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"День рождения\",\"startDate\":\"2026-09-01\",\"allDay\":true,\"budget\":30000}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.aiReminderId").isNotEmpty())
                .andReturn();

        mockMvc.perform(get("/api/v1/ai/reminders")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].eventName").value("День рождения"));

        String eventId = objectMapper.readTree(created.getResponse().getContentAsString())
                .path("data").path("id").asText();
        mockMvc.perform(delete("/api/v1/events/" + eventId)
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk());
        mockMvc.perform(get("/api/v1/ai/reminders")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(0));
    }

    @Test
    void recurringWithBudgetRejected() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        mockMvc.perform(post("/api/v1/events")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Bad\",\"startDate\":\"2026-06-01\",\"allDay\":true,\"recurFreq\":\"WEEKLY\",\"budget\":1000}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("VALIDATION_FAILED"));
    }

    @Test
    void personalEventNotVisibleToAnotherUser() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser other = testAuth.createUser();
        mockMvc.perform(post("/api/v1/events")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Личное\",\"startDate\":\"2026-07-10\",\"allDay\":true}"))
                .andExpect(status().isOk());
        mockMvc.perform(get("/api/v1/events?from=2026-07-01&to=2026-07-31")
                        .header(HttpHeaders.AUTHORIZATION, other.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(0));
    }
}
