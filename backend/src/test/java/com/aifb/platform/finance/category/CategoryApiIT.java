package com.aifb.platform.finance.category;

import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;

import static org.hamcrest.Matchers.greaterThan;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class CategoryApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;

    @Test
    void listRequiresAuth() throws Exception {
        mockMvc.perform(get("/api/v1/categories").param("type", "EXPENSE"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void listReturnsSystemCategories() throws Exception {
        String bearer = testAuth.createUser().bearer();
        mockMvc.perform(get("/api/v1/categories")
                        .param("type", "EXPENSE")
                        .header(HttpHeaders.AUTHORIZATION, bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()", greaterThan(0)))
                .andExpect(jsonPath("$.data[0].type").value("EXPENSE"));
    }

    @Test
    void createReturnsCreatedCategory() throws Exception {
        String bearer = testAuth.createUser().bearer();
        mockMvc.perform(post("/api/v1/categories")
                        .header(HttpHeaders.AUTHORIZATION, bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"Кафе","type":"EXPENSE","icon":"coffee","color":"#FFAA00"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Кафе"))
                .andExpect(jsonPath("$.data.system").value(false));
    }

    @Test
    void createRejectsBlankName() throws Exception {
        String bearer = testAuth.createUser().bearer();
        mockMvc.perform(post("/api/v1/categories")
                        .header(HttpHeaders.AUTHORIZATION, bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"","type":"EXPENSE"}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("VALIDATION_FAILED"));
    }
}
