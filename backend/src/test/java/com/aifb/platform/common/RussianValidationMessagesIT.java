package com.aifb.platform.common;

import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.service.HouseholdService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Verifies that ValidationMessages.properties is picked up with proper UTF-8 encoding
 * and that validation error messages are returned in Russian.
 */
class RussianValidationMessagesIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired HouseholdService householdService;

    @Test
    void blankShoppingItemTitle_returnsRussianValidationMessage() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        householdService.create(owner.id(), new CreateHouseholdRequest("Семья"));

        // POST with blank title → @NotBlank fires → should return Russian message
        mockMvc.perform(post("/api/v1/shopping")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.fields.title").value(
                        org.hamcrest.Matchers.containsString("обязательное")));
    }

    @Test
    void blankLoginEmail_returnsRussianValidationMessage() throws Exception {
        // POST /api/v1/auth/login with blank email → @NotBlank fires
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"\",\"password\":\"secret123\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.fields.email").value(
                        org.hamcrest.Matchers.containsString("обязательное")));
    }
}
