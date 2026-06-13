package com.aifb.platform.notification;

import com.aifb.platform.notification.repository.DeviceTokenRepository;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class PushApiIT extends AbstractIntegrationTest {

    @Autowired MockMvc mockMvc;
    @Autowired TestAuth testAuth;
    @Autowired DeviceTokenRepository tokens;

    @Test
    void requiresAuth() throws Exception {
        mockMvc.perform(post("/api/v1/push/tokens")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"t\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void registerThenDeleteToken() throws Exception {
        TestAuth.AuthedUser u = testAuth.createUser();
        mockMvc.perform(post("/api/v1/push/tokens")
                        .header(HttpHeaders.AUTHORIZATION, u.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"tok-it\",\"platform\":\"ANDROID\"}"))
                .andExpect(status().isOk());
        assertThat(tokens.findByToken("tok-it")).isPresent();

        mockMvc.perform(delete("/api/v1/push/tokens/{t}", "tok-it")
                        .header(HttpHeaders.AUTHORIZATION, u.bearer()))
                .andExpect(status().isOk());
        assertThat(tokens.findByToken("tok-it")).isEmpty();
    }

    @Test
    void testEndpointReturnsOk() throws Exception {
        TestAuth.AuthedUser u = testAuth.createUser();
        mockMvc.perform(post("/api/v1/push/tokens")
                        .header(HttpHeaders.AUTHORIZATION, u.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"tok-test\"}"))
                .andExpect(status().isOk());
        mockMvc.perform(post("/api/v1/push/test")
                        .header(HttpHeaders.AUTHORIZATION, u.bearer()))
                .andExpect(status().isOk());
    }
}
