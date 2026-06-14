package com.aifb.platform.shopping;

import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.domain.HouseholdRole;
import com.aifb.platform.household.service.HouseholdService;
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

class ShoppingApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired ObjectMapper objectMapper;
    @Autowired HouseholdService householdService;

    @Test
    void authRequired() throws Exception {
        mockMvc.perform(get("/api/v1/shopping"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void addAndListContainsItem() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        householdService.create(owner.id(), new CreateHouseholdRequest("Семья"));

        mockMvc.perform(post("/api/v1/shopping")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Молоко\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("Молоко"))
                .andExpect(jsonPath("$.data.checked").value(false));

        mockMvc.perform(get("/api/v1/shopping")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.title == 'Молоко')]").exists());
    }

    @Test
    void toggleFlipsChecked() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        householdService.create(owner.id(), new CreateHouseholdRequest("Семья"));

        MvcResult addResult = mockMvc.perform(post("/api/v1/shopping")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Хлеб\"}"))
                .andExpect(status().isOk())
                .andReturn();

        String itemId = objectMapper.readTree(addResult.getResponse().getContentAsString())
                .path("data").path("id").asText();

        mockMvc.perform(post("/api/v1/shopping/" + itemId + "/toggle")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.checked").value(true));

        mockMvc.perform(get("/api/v1/shopping")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == '" + itemId + "')].checked").value(true));
    }

    @Test
    void deleteRemovesItem() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        householdService.create(owner.id(), new CreateHouseholdRequest("Семья"));

        MvcResult addResult = mockMvc.perform(post("/api/v1/shopping")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Сыр\"}"))
                .andExpect(status().isOk())
                .andReturn();

        String itemId = objectMapper.readTree(addResult.getResponse().getContentAsString())
                .path("data").path("id").asText();

        mockMvc.perform(delete("/api/v1/shopping/" + itemId)
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/v1/shopping")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == '" + itemId + "')]").doesNotExist());
    }

    @Test
    void familyScopeMemberSeesOwnerItem() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser member = testAuth.createUser();

        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(member.id(), new JoinHouseholdRequest(code));

        mockMvc.perform(post("/api/v1/shopping")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Яблоки\"}"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/v1/shopping")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.title == 'Яблоки')]").exists());
    }

    @Test
    void guestCannotAdd() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser guest = testAuth.createUser();

        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(guest.id(), new JoinHouseholdRequest(code));
        householdService.changeRole(owner.id(), guest.id(), HouseholdRole.GUEST);

        mockMvc.perform(post("/api/v1/shopping")
                        .header(HttpHeaders.AUTHORIZATION, guest.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Запрещено\"}"))
                .andExpect(status().isForbidden());
    }
}
