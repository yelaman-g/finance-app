package com.aifb.platform.social.reaction;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
import com.aifb.platform.finance.transaction.api.dto.TransactionResponse;
import com.aifb.platform.finance.transaction.service.TransactionService;
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

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class ReactionApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired ObjectMapper objectMapper;
    @Autowired HouseholdService householdService;
    @Autowired TransactionService transactionService;
    @Autowired CategoryService categoryService;

    /** Helper: family-scope expense category id for a user already in a household. */
    private UUID familyExpenseCat(UUID userId) {
        return categoryService.list(userId, CategoryType.EXPENSE, Scope.FAMILY).get(0).id();
    }

    /** Helper: create a shared transaction for the given owner (already in a household). */
    private UUID sharedTx(UUID ownerId) {
        UUID cat = familyExpenseCat(ownerId);
        TransactionResponse tx = transactionService.create(ownerId,
                new CreateTransactionRequest(cat, CategoryType.EXPENSE,
                        new BigDecimal("250.00"), "dinner", LocalDate.now(), true));
        return tx.id();
    }

    /** Helper: create a personal (non-shared) transaction for the given user. */
    private UUID personalTx(UUID ownerId) {
        // Use a personal EXPENSE category
        UUID cat = categoryService.list(ownerId, CategoryType.EXPENSE, Scope.PERSONAL).get(0).id();
        TransactionResponse tx = transactionService.create(ownerId,
                new CreateTransactionRequest(cat, CategoryType.EXPENSE,
                        new BigDecimal("50.00"), "personal", LocalDate.now(), false));
        return tx.id();
    }

    // -------------------------------------------------------------------------
    // Auth required
    // -------------------------------------------------------------------------

    @Test
    void reactRequiresAuth() throws Exception {
        UUID txId = UUID.randomUUID();
        mockMvc.perform(post("/api/v1/transactions/" + txId + "/reactions")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"emoji\":\"😅\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void deleteReactionRequiresAuth() throws Exception {
        UUID txId = UUID.randomUUID();
        mockMvc.perform(delete("/api/v1/transactions/" + txId + "/reactions"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void getReactionsRequiresAuth() throws Exception {
        UUID txId = UUID.randomUUID();
        mockMvc.perform(get("/api/v1/transactions/reactions")
                        .param("transactionIds", txId.toString()))
                .andExpect(status().isUnauthorized());
    }

    // -------------------------------------------------------------------------
    // Member reacts to owner's shared transaction → GET returns the reaction
    // -------------------------------------------------------------------------

    @Test
    void memberReactsAndGetReturnsIt() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser member = testAuth.createUser();

        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(member.id(), new JoinHouseholdRequest(code));

        UUID txId = sharedTx(owner.id());

        // member reacts
        mockMvc.perform(post("/api/v1/transactions/" + txId + "/reactions")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"emoji\":\"😅\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isEmpty());

        // GET batch — returns the reaction
        mockMvc.perform(get("/api/v1/transactions/reactions")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer())
                        .param("transactionIds", txId.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data['" + txId + "'][0].emoji").value("😅"))
                .andExpect(jsonPath("$.data['" + txId + "'][0].userId").value(member.id().toString()));
    }

    // -------------------------------------------------------------------------
    // Re-react replaces emoji (upsert)
    // -------------------------------------------------------------------------

    @Test
    void reReactReplacesEmoji() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser member = testAuth.createUser();

        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(member.id(), new JoinHouseholdRequest(code));

        UUID txId = sharedTx(owner.id());

        // react with 😅
        mockMvc.perform(post("/api/v1/transactions/" + txId + "/reactions")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"emoji\":\"😅\"}"))
                .andExpect(status().isOk());

        // react again with 👍
        mockMvc.perform(post("/api/v1/transactions/" + txId + "/reactions")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"emoji\":\"👍\"}"))
                .andExpect(status().isOk());

        // GET should show only 👍, only one reaction entry
        mockMvc.perform(get("/api/v1/transactions/reactions")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer())
                        .param("transactionIds", txId.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data['" + txId + "'].length()").value(1))
                .andExpect(jsonPath("$.data['" + txId + "'][0].emoji").value("👍"));
    }

    // -------------------------------------------------------------------------
    // DELETE removes the reaction
    // -------------------------------------------------------------------------

    @Test
    void deleteRemovesReaction() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser member = testAuth.createUser();

        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(member.id(), new JoinHouseholdRequest(code));

        UUID txId = sharedTx(owner.id());

        // react
        mockMvc.perform(post("/api/v1/transactions/" + txId + "/reactions")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"emoji\":\"❤️\"}"))
                .andExpect(status().isOk());

        // delete reaction
        mockMvc.perform(delete("/api/v1/transactions/" + txId + "/reactions")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer()))
                .andExpect(status().isOk());

        // GET shows empty list for this tx
        mockMvc.perform(get("/api/v1/transactions/reactions")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer())
                        .param("transactionIds", txId.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data['" + txId + "']").doesNotExist());
    }

    // -------------------------------------------------------------------------
    // GUEST cannot react (403)
    // -------------------------------------------------------------------------

    @Test
    void guestCannotReact() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser guest = testAuth.createUser();

        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(guest.id(), new JoinHouseholdRequest(code));
        householdService.changeRole(owner.id(), guest.id(), HouseholdRole.GUEST);

        UUID txId = sharedTx(owner.id());

        mockMvc.perform(post("/api/v1/transactions/" + txId + "/reactions")
                        .header(HttpHeaders.AUTHORIZATION, guest.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"emoji\":\"😅\"}"))
                .andExpect(status().isForbidden());
    }

    // -------------------------------------------------------------------------
    // Personal (non-shared) transaction → 403 when reacting
    // -------------------------------------------------------------------------

    @Test
    void reactingToPersonalTransactionIsForbidden() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        // owner is NOT in a household for this test — just a personal user
        UUID txId = personalTx(owner.id());

        mockMvc.perform(post("/api/v1/transactions/" + txId + "/reactions")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"emoji\":\"😅\"}"))
                .andExpect(status().isForbidden());
    }
}
