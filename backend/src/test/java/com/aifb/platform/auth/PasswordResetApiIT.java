package com.aifb.platform.auth;

import com.aifb.platform.support.AbstractIntegrationTest;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MvcResult;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class PasswordResetApiIT extends AbstractIntegrationTest {

    @Autowired
    ObjectMapper objectMapper;

    private String uniqueEmail() {
        return "x-" + UUID.randomUUID() + "@example.com";
    }

    private void register(String email, String password) throws Exception {
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"fullName\":\"Test User\",\"email\":\"" + email
                                + "\",\"password\":\"" + password + "\"}"))
                .andExpect(status().isCreated());
    }

    private String requestCode(String email) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/v1/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString())
                .path("data").path("devCode").asText(null);
    }

    private void login(String email, String password, int expectedStatus) throws Exception {
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
                .andExpect(status().is(expectedStatus));
    }

    @Test
    void forgotReturnsDevCodeForKnownEmail() throws Exception {
        String email = uniqueEmail();
        register(email, "oldpass123");

        String code = requestCode(email);

        assertThat(code).isNotNull();
        assertThat(code).hasSize(6);
        assertThat(code).matches("\\d{6}");
    }

    @Test
    void forgotReturnsNullDevCodeForUnknownEmail() throws Exception {
        mockMvc.perform(post("/api/v1/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + uniqueEmail() + "\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.devCode").doesNotExist());
    }

    @Test
    void resetWithValidCodeChangesPassword() throws Exception {
        String email = uniqueEmail();
        register(email, "oldpass123");

        String code = requestCode(email);

        mockMvc.perform(post("/api/v1/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"code\":\"" + code
                                + "\",\"newPassword\":\"newpass123\"}"))
                .andExpect(status().isOk());

        login(email, "newpass123", 200);
        login(email, "oldpass123", 401);
    }

    @Test
    void codeIsSingleUse() throws Exception {
        String email = uniqueEmail();
        register(email, "oldpass123");

        String code = requestCode(email);

        mockMvc.perform(post("/api/v1/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"code\":\"" + code
                                + "\",\"newPassword\":\"newpass123\"}"))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/v1/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"code\":\"" + code
                                + "\",\"newPassword\":\"newpass123\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("AUTH_RESET_CODE_INVALID"));
    }

    @Test
    void resetWithWrongCodeFails() throws Exception {
        String email = uniqueEmail();
        register(email, "oldpass123");

        String code = requestCode(email);
        String wrongCode = "000000".equals(code) ? "000001" : "000000";

        mockMvc.perform(post("/api/v1/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"code\":\"" + wrongCode
                                + "\",\"newPassword\":\"newpass123\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("AUTH_RESET_CODE_INVALID"));
    }

    @Test
    void newRequestInvalidatesPreviousCode() throws Exception {
        String email = uniqueEmail();
        register(email, "oldpass123");

        String code1 = requestCode(email);
        String code2 = requestCode(email);
        assertThat(code2).isNotEqualTo(code1);

        mockMvc.perform(post("/api/v1/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"code\":\"" + code1
                                + "\",\"newPassword\":\"newpass123\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("AUTH_RESET_CODE_INVALID"));

        mockMvc.perform(post("/api/v1/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"code\":\"" + code2
                                + "\",\"newPassword\":\"newpass123\"}"))
                .andExpect(status().isOk());
    }
}
