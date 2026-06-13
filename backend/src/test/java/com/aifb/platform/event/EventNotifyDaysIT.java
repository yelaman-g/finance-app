package com.aifb.platform.event;

import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class EventNotifyDaysIT extends AbstractIntegrationTest {

    @Autowired MockMvc mockMvc;
    @Autowired TestAuth testAuth;

    @Test
    void createStoresNotifyDaysBefore() throws Exception {
        TestAuth.AuthedUser u = testAuth.createUser();
        mockMvc.perform(post("/api/v1/events")
                        .header(HttpHeaders.AUTHORIZATION, u.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Урок\",\"startDate\":\"2026-09-01\",\"allDay\":true,\"notifyDaysBefore\":[3,1,0]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.notifyDaysBefore[0]").value(3))
                .andExpect(jsonPath("$.data.notifyDaysBefore[2]").value(0));
    }

    @Test
    void createWithoutNotifyDaysDefaultsTo1And0() throws Exception {
        TestAuth.AuthedUser u = testAuth.createUser();
        mockMvc.perform(post("/api/v1/events")
                        .header(HttpHeaders.AUTHORIZATION, u.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Встреча\",\"startDate\":\"2026-09-01\",\"allDay\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.notifyDaysBefore[0]").value(1))
                .andExpect(jsonPath("$.data.notifyDaysBefore[1]").value(0));
    }
}
