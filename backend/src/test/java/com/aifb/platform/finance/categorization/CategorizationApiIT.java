package com.aifb.platform.finance.categorization;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;

import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class CategorizationApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired CategoryService categoryService;

    @Test
    void rulesRequireAuth() throws Exception {
        mockMvc.perform(get("/api/v1/categorization/rules"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void createRuleAndSuggest() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        UUID cat = categoryService.list(user.id(), CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
        mockMvc.perform(post("/api/v1/categorization/rules")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"keyword\":\"magnum\",\"categoryId\":\"" + cat + "\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.keyword").value("magnum"));

        mockMvc.perform(post("/api/v1/categorization/suggest")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"note\":\"покупка в MAGNUM\",\"type\":\"EXPENSE\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.categoryId").value(cat.toString()));
    }

    @Test
    void suggestNoMatchReturnsNullData() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        mockMvc.perform(post("/api/v1/categorization/suggest")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"note\":\"ничего\",\"type\":\"EXPENSE\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").doesNotExist());
    }
}
