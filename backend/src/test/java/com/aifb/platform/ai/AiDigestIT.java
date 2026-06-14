package com.aifb.platform.ai;

import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;

import java.time.LocalDate;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AiDigestIT extends AbstractIntegrationTest {

    @Autowired
    TestAuth testAuth;

    @Test
    void digestRequiresAuth() throws Exception {
        mockMvc.perform(get("/api/v1/ai/digest"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void digestReturnsNarrativeAndTip() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        mockMvc.perform(get("/api/v1/ai/digest")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.narrative").isNotEmpty())
                .andExpect(jsonPath("$.data.tipOfDay").isNotEmpty())
                .andExpect(jsonPath("$.data.highlights").isArray())
                .andExpect(jsonPath("$.data.upcomingEvents").isArray());
    }

    @Test
    void digestIncludesNearFutureEvent() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        String eventDate = LocalDate.now().plusDays(3).toString();

        mockMvc.perform(post("/api/v1/events")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Дайджест-тест\",\"startDate\":\"" + eventDate + "\",\"allDay\":true}"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/v1/ai/digest")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.upcomingEvents[?(@.title == 'Дайджест-тест')]").exists());
    }
}
