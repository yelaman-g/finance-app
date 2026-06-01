package com.aifb.platform.household;

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

class HouseholdApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired ObjectMapper objectMapper;

    @Test
    void createJoinFlow() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        MvcResult created = mockMvc.perform(post("/api/v1/households")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Семья\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.myRole").value("OWNER"))
                .andExpect(jsonPath("$.data.inviteCode").isNotEmpty())
                .andReturn();
        String code = objectMapper.readTree(created.getResponse().getContentAsString())
                .path("data").path("inviteCode").asText();

        TestAuth.AuthedUser joiner = testAuth.createUser();
        mockMvc.perform(post("/api/v1/households/join")
                        .header(HttpHeaders.AUTHORIZATION, joiner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"inviteCode\":\"" + code + "\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.myRole").value("ADULT"))
                .andExpect(jsonPath("$.data.members.length()").value(2));
    }

    @Test
    void getMineRequiresAuth() throws Exception {
        mockMvc.perform(get("/api/v1/households/me"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void getMineWithoutHouseholdReturns404() throws Exception {
        TestAuth.AuthedUser u = testAuth.createUser();
        mockMvc.perform(get("/api/v1/households/me")
                        .header(HttpHeaders.AUTHORIZATION, u.bearer()))
                .andExpect(status().isNotFound());
    }
}
