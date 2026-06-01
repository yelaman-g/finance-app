package com.aifb.platform.finance.group;

import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class CategoryGroupApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;

    @Test
    void listRequiresAuth() throws Exception {
        mockMvc.perform(get("/api/v1/groups").param("type", "EXPENSE"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void createAndListGroup() throws Exception {
        String bearer = testAuth.createUser().bearer();
        mockMvc.perform(post("/api/v1/groups")
                        .header(HttpHeaders.AUTHORIZATION, bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Коммунальные\",\"type\":\"EXPENSE\",\"icon\":\"home\",\"color\":\"#888888\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Коммунальные"))
                .andExpect(jsonPath("$.data.shared").value(false));

        mockMvc.perform(get("/api/v1/groups").param("type", "EXPENSE").param("scope", "PERSONAL")
                        .header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].name").value("Коммунальные"));
    }

    @Test
    void createRejectsBlankName() throws Exception {
        String bearer = testAuth.createUser().bearer();
        mockMvc.perform(post("/api/v1/groups")
                        .header(HttpHeaders.AUTHORIZATION, bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"\",\"type\":\"EXPENSE\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("VALIDATION_FAILED"));
    }
}
