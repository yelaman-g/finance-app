package com.aifb.platform.finance.scope;

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

class ScopeApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired ObjectMapper objectMapper;

    @Test
    void sharedTransactionFlowViaHttp() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        mockMvc.perform(post("/api/v1/households")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Семья\"}"))
                .andExpect(status().isOk());

        MvcResult cats = mockMvc.perform(get("/api/v1/categories")
                        .param("type", "EXPENSE").param("scope", "FAMILY")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk()).andReturn();
        JsonNode arr = objectMapper.readTree(cats.getResponse().getContentAsString()).path("data");
        String catId = arr.get(0).path("id").asText();

        mockMvc.perform(post("/api/v1/transactions")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"categoryId\":\"" + catId + "\",\"type\":\"EXPENSE\",\"amount\":100.00,\"occurredOn\":\"" + java.time.LocalDate.now() + "\",\"shared\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.shared").value(true));

        mockMvc.perform(get("/api/v1/transactions").param("scope", "FAMILY")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(jsonPath("$.data.total").value(1));
        mockMvc.perform(get("/api/v1/transactions").param("scope", "PERSONAL")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(jsonPath("$.data.total").value(0));

        mockMvc.perform(get("/api/v1/statistics/by-member")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1));
    }
}
