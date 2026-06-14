package com.aifb.platform.social.wishlist;

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

import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class WishlistApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired ObjectMapper objectMapper;
    @Autowired HouseholdService householdService;

    // -------------------------------------------------------------------------
    // Auth required
    // -------------------------------------------------------------------------

    @Test
    void authRequired_list() throws Exception {
        mockMvc.perform(get("/api/v1/wishlist"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void authRequired_add() throws Exception {
        mockMvc.perform(post("/api/v1/wishlist")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Книга\"}"))
                .andExpect(status().isUnauthorized());
    }

    // -------------------------------------------------------------------------
    // Owner adds item → GET by another member shows it with ownerName
    // -------------------------------------------------------------------------

    @Test
    void ownerAddsItem_memberSeesItWithOwnerName() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser member = testAuth.createUser();

        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(member.id(), new JoinHouseholdRequest(code));

        mockMvc.perform(post("/api/v1/wishlist")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Велосипед\",\"note\":\"Горный\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("Велосипед"))
                .andExpect(jsonPath("$.data.note").value("Горный"))
                .andExpect(jsonPath("$.data.reserved").value(false));

        mockMvc.perform(get("/api/v1/wishlist")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.title == 'Велосипед')]").exists())
                .andExpect(jsonPath("$.data[?(@.title == 'Велосипед')].ownerName").value("Test User"))
                .andExpect(jsonPath("$.data[?(@.title == 'Велосипед')].ownerId").value(owner.id().toString()));
    }

    // -------------------------------------------------------------------------
    // Another member reserves item → GET shows reserved=true, reservedBy=that member
    // -------------------------------------------------------------------------

    @Test
    void memberReservesItem_showsReservedTrue() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser reserver = testAuth.createUser();

        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(reserver.id(), new JoinHouseholdRequest(code));

        // owner adds item
        MvcResult addResult = mockMvc.perform(post("/api/v1/wishlist")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Книга\"}"))
                .andExpect(status().isOk())
                .andReturn();

        String itemId = objectMapper.readTree(addResult.getResponse().getContentAsString())
                .path("data").path("id").asText();

        // another member reserves it
        mockMvc.perform(post("/api/v1/wishlist/" + itemId + "/reserve")
                        .header(HttpHeaders.AUTHORIZATION, reserver.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.reserved").value(true))
                .andExpect(jsonPath("$.data.reservedBy").value(reserver.id().toString()));

        // GET shows reserved=true
        mockMvc.perform(get("/api/v1/wishlist")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == '" + itemId + "')].reserved").value(true))
                .andExpect(jsonPath("$.data[?(@.id == '" + itemId + "')].reservedBy")
                        .value(reserver.id().toString()));
    }

    // -------------------------------------------------------------------------
    // Cannot reserve OWN item → 403
    // -------------------------------------------------------------------------

    @Test
    void cannotReserveOwnItem() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        householdService.create(owner.id(), new CreateHouseholdRequest("Семья"));

        MvcResult addResult = mockMvc.perform(post("/api/v1/wishlist")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Наушники\"}"))
                .andExpect(status().isOk())
                .andReturn();

        String itemId = objectMapper.readTree(addResult.getResponse().getContentAsString())
                .path("data").path("id").asText();

        mockMvc.perform(post("/api/v1/wishlist/" + itemId + "/reserve")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isForbidden());
    }

    // -------------------------------------------------------------------------
    // Only reserver can unreserve; other member → 403; reserver → ok
    // -------------------------------------------------------------------------

    @Test
    void onlyReserverCanUnreserve() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser reserver = testAuth.createUser();
        TestAuth.AuthedUser other = testAuth.createUser();

        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(reserver.id(), new JoinHouseholdRequest(code));
        householdService.join(other.id(), new JoinHouseholdRequest(code));

        // owner adds item
        MvcResult addResult = mockMvc.perform(post("/api/v1/wishlist")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Планшет\"}"))
                .andExpect(status().isOk())
                .andReturn();

        String itemId = objectMapper.readTree(addResult.getResponse().getContentAsString())
                .path("data").path("id").asText();

        // reserver reserves it
        mockMvc.perform(post("/api/v1/wishlist/" + itemId + "/reserve")
                        .header(HttpHeaders.AUTHORIZATION, reserver.bearer()))
                .andExpect(status().isOk());

        // other member tries to unreserve → 403
        mockMvc.perform(delete("/api/v1/wishlist/" + itemId + "/reserve")
                        .header(HttpHeaders.AUTHORIZATION, other.bearer()))
                .andExpect(status().isForbidden());

        // reserver unreserves → ok
        mockMvc.perform(delete("/api/v1/wishlist/" + itemId + "/reserve")
                        .header(HttpHeaders.AUTHORIZATION, reserver.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.reserved").value(false))
                .andExpect(jsonPath("$.data.reservedBy").doesNotExist());
    }

    // -------------------------------------------------------------------------
    // Owner deletes own item; non-owner delete → 403/404
    // -------------------------------------------------------------------------

    @Test
    void ownerDeletesOwnItem() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        householdService.create(owner.id(), new CreateHouseholdRequest("Семья"));

        MvcResult addResult = mockMvc.perform(post("/api/v1/wishlist")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Удалить меня\"}"))
                .andExpect(status().isOk())
                .andReturn();

        String itemId = objectMapper.readTree(addResult.getResponse().getContentAsString())
                .path("data").path("id").asText();

        mockMvc.perform(delete("/api/v1/wishlist/" + itemId)
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/v1/wishlist")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == '" + itemId + "')]").doesNotExist());
    }

    @Test
    void nonOwnerDeleteIsForbidden() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser member = testAuth.createUser();

        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(member.id(), new JoinHouseholdRequest(code));

        MvcResult addResult = mockMvc.perform(post("/api/v1/wishlist")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Чужая вещь\"}"))
                .andExpect(status().isOk())
                .andReturn();

        String itemId = objectMapper.readTree(addResult.getResponse().getContentAsString())
                .path("data").path("id").asText();

        mockMvc.perform(delete("/api/v1/wishlist/" + itemId)
                        .header(HttpHeaders.AUTHORIZATION, member.bearer()))
                .andExpect(status().isForbidden());
    }

    // -------------------------------------------------------------------------
    // GUEST cannot add (403)
    // -------------------------------------------------------------------------

    @Test
    void guestCannotAdd() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser guest = testAuth.createUser();

        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(guest.id(), new JoinHouseholdRequest(code));
        householdService.changeRole(owner.id(), guest.id(), HouseholdRole.GUEST);

        mockMvc.perform(post("/api/v1/wishlist")
                        .header(HttpHeaders.AUTHORIZATION, guest.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"Запрещено\"}"))
                .andExpect(status().isForbidden());
    }
}
