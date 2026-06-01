package com.aifb.platform.finance.budget;

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

class BudgetApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired CategoryService categoryService;

    @Test
    void listRequiresAuth() throws Exception {
        mockMvc.perform(get("/api/v1/budgets"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void createAndListBudget() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        UUID cat = categoryService.list(user.id(), CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
        mockMvc.perform(post("/api/v1/budgets")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"targetType\":\"CATEGORY\",\"categoryId\":\"" + cat + "\",\"amount\":1000.00}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("OK"))
                .andExpect(jsonPath("$.data.spent").value(0));

        mockMvc.perform(get("/api/v1/budgets").param("scope", "PERSONAL")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1));
    }

    @Test
    void createRejectsNonPositiveAmount() throws Exception {
        TestAuth.AuthedUser user = testAuth.createUser();
        UUID cat = categoryService.list(user.id(), CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
        mockMvc.perform(post("/api/v1/budgets")
                        .header(HttpHeaders.AUTHORIZATION, user.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"targetType\":\"CATEGORY\",\"categoryId\":\"" + cat + "\",\"amount\":0}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("VALIDATION_FAILED"));
    }
}
