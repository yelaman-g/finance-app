package com.aifb.platform.auth;

import com.aifb.platform.support.AbstractIntegrationTest;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MvcResult;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class GoogleAuthApiIT extends AbstractIntegrationTest {

    @Autowired
    ObjectMapper objectMapper;

    private String uniqueEmail() {
        return "g-" + UUID.randomUUID() + "@example.com";
    }

    private String devToken(String sub, String email, String name, boolean emailVerified) {
        String json = "{\"sub\":\"" + sub + "\",\"email\":\"" + email + "\",\"name\":\"" + name
                + "\",\"email_verified\":" + emailVerified + "}";
        return "dev." + Base64.getUrlEncoder().withoutPadding()
                .encodeToString(json.getBytes(StandardCharsets.UTF_8));
    }

    private MvcResult google(String idToken, int expectedStatus) throws Exception {
        return mockMvc.perform(post("/api/v1/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"idToken\":\"" + idToken + "\"}"))
                .andExpect(status().is(expectedStatus))
                .andReturn();
    }

    private String userId(MvcResult result) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString())
                .path("data").path("user").path("id").asText();
    }

    @Test
    void newUserIsCreatedAndSessionIssued() throws Exception {
        String email = uniqueEmail();
        MvcResult result = google(devToken("sub-" + email, email, "New User", true), 200);

        assertThat(objectMapper.readTree(result.getResponse().getContentAsString())
                .path("data").path("tokens").path("accessToken").asText()).isNotBlank();
        mockMvc.perform(post("/api/v1/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"idToken\":\"" + devToken("sub-" + email, email, "New User", true) + "\"}"))
                .andExpect(jsonPath("$.data.user.email").value(email))
                .andExpect(jsonPath("$.data.user.emailVerified").value(true));
    }

    @Test
    void sameSubjectReturnsSameUser() throws Exception {
        String email = uniqueEmail();
        String token = devToken("sub-" + email, email, "Stable", true);
        String id1 = userId(google(token, 200));
        String id2 = userId(google(token, 200));
        assertThat(id2).isEqualTo(id1);
    }

    @Test
    void existingEmailAccountIsLinked() throws Exception {
        String email = uniqueEmail();
        MvcResult reg = mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"fullName\":\"Local User\",\"email\":\"" + email
                                + "\",\"password\":\"password1\"}"))
                .andExpect(status().isCreated())
                .andReturn();
        String regId = userId(reg);

        String googleId = userId(google(devToken("sub-" + email, email, "Local User", true), 200));
        assertThat(googleId).isEqualTo(regId);
    }

    @Test
    void invalidTokenIsRejected() throws Exception {
        mockMvc.perform(post("/api/v1/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"idToken\":\"garbage-token\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error.code").value("AUTH_GOOGLE_TOKEN_INVALID"));
    }

    @Test
    void unverifiedEmailIsRejected() throws Exception {
        String email = uniqueEmail();
        mockMvc.perform(post("/api/v1/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"idToken\":\"" + devToken("sub-" + email, email, "X", false) + "\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error.code").value("AUTH_GOOGLE_TOKEN_INVALID"));
    }

    @Test
    void passwordLoginRejectedForGoogleOnlyAccount() throws Exception {
        String email = uniqueEmail();
        google(devToken("sub-" + email, email, "No Pass", true), 200);

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"whatever1\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error.code").value("AUTH_INVALID_CREDENTIALS"));
    }

    @Test
    void googleOnlyAccountCannotRequestPasswordReset() throws Exception {
        String email = uniqueEmail();
        google(devToken("sub-" + email, email, "Reset Guard", true), 200);

        // у Google-аккаунта нет локального пароля → forgot-password не выдаёт код
        mockMvc.perform(post("/api/v1/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.devCode").doesNotExist());
    }
}
