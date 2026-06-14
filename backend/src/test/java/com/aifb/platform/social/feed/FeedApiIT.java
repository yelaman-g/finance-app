package com.aifb.platform.social.feed;

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

import java.util.Map;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class FeedApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired ObjectMapper objectMapper;
    @Autowired HouseholdService householdService;

    // -------------------------------------------------------------------------
    // Auth required (no token → 401)
    // -------------------------------------------------------------------------

    @Test
    void authRequired_list() throws Exception {
        mockMvc.perform(get("/api/v1/feed"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void authRequired_post() throws Exception {
        mockMvc.perform(post("/api/v1/feed")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"text\":\"hello\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void authRequired_delete() throws Exception {
        mockMvc.perform(delete("/api/v1/feed/" + UUID.randomUUID()))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void authRequired_like() throws Exception {
        mockMvc.perform(post("/api/v1/feed/" + UUID.randomUUID() + "/like"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void authRequired_unlike() throws Exception {
        mockMvc.perform(delete("/api/v1/feed/" + UUID.randomUUID() + "/like"))
                .andExpect(status().isUnauthorized());
    }

    // -------------------------------------------------------------------------
    // Post moment → GET by another member shows it with authorName, likes=0, likedByMe=false
    // -------------------------------------------------------------------------

    @Test
    void postMoment_visibleToOtherMemberWithAuthorNameAndZeroLikes() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser("Алия Бекова");
        TestAuth.AuthedUser member = testAuth.createUser("Ержан Мусин");
        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(member.id(), new JoinHouseholdRequest(code));

        // Owner posts a moment
        MvcResult postResult = mockMvc.perform(post("/api/v1/feed")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"text\":\"Сегодня отличный день!\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.text").value("Сегодня отличный день!"))
                .andExpect(jsonPath("$.data.authorName").value("Алия Бекова"))
                .andExpect(jsonPath("$.data.likes").value(0))
                .andExpect(jsonPath("$.data.likedByMe").value(false))
                .andReturn();

        String momentId = objectMapper.readTree(postResult.getResponse().getContentAsString())
                .path("data").path("id").asText();

        // Member sees the moment in list
        mockMvc.perform(get("/api/v1/feed")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == '" + momentId + "')].text").value("Сегодня отличный день!"))
                .andExpect(jsonPath("$.data[?(@.id == '" + momentId + "')].authorName").value("Алия Бекова"))
                .andExpect(jsonPath("$.data[?(@.id == '" + momentId + "')].likes").value(0))
                .andExpect(jsonPath("$.data[?(@.id == '" + momentId + "')].likedByMe").value(false));
    }

    // -------------------------------------------------------------------------
    // Like by member → likes=1, likedByMe=true; unlike → likes=0, likedByMe=false
    // -------------------------------------------------------------------------

    @Test
    void like_incrementsCount_unlike_decrementsBack() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser("Алия");
        TestAuth.AuthedUser member = testAuth.createUser("Ержан");
        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(member.id(), new JoinHouseholdRequest(code));

        // Post moment
        MvcResult postResult = mockMvc.perform(post("/api/v1/feed")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"text\":\"Новый момент\"}"))
                .andExpect(status().isOk())
                .andReturn();

        String momentId = objectMapper.readTree(postResult.getResponse().getContentAsString())
                .path("data").path("id").asText();

        // Member likes
        mockMvc.perform(post("/api/v1/feed/" + momentId + "/like")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer()))
                .andExpect(status().isOk());

        // Check likes=1, likedByMe=true for member
        mockMvc.perform(get("/api/v1/feed")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == '" + momentId + "')].likes").value(1))
                .andExpect(jsonPath("$.data[?(@.id == '" + momentId + "')].likedByMe").value(true));

        // Member unlikes
        mockMvc.perform(delete("/api/v1/feed/" + momentId + "/like")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer()))
                .andExpect(status().isOk());

        // Check likes=0, likedByMe=false
        mockMvc.perform(get("/api/v1/feed")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == '" + momentId + "')].likes").value(0))
                .andExpect(jsonPath("$.data[?(@.id == '" + momentId + "')].likedByMe").value(false));
    }

    // -------------------------------------------------------------------------
    // Author deletes own moment → 200; moment gone from feed
    // -------------------------------------------------------------------------

    @Test
    void authorDeletesOwnMoment_momentRemovedFromFeed() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser("Алия");
        householdService.create(owner.id(), new CreateHouseholdRequest("Семья"));

        MvcResult postResult = mockMvc.perform(post("/api/v1/feed")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"text\":\"Удалю это\"}"))
                .andExpect(status().isOk())
                .andReturn();

        String momentId = objectMapper.readTree(postResult.getResponse().getContentAsString())
                .path("data").path("id").asText();

        mockMvc.perform(delete("/api/v1/feed/" + momentId)
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/v1/feed")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == '" + momentId + "')]").doesNotExist());
    }

    // -------------------------------------------------------------------------
    // Non-author CHILD cannot delete → 403
    // -------------------------------------------------------------------------

    @Test
    void childNonAuthorCannotDelete_returns403() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser("Алия");
        TestAuth.AuthedUser child = testAuth.createUser("Дочь");
        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(child.id(), new JoinHouseholdRequest(code));
        householdService.changeRole(owner.id(), child.id(), HouseholdRole.CHILD);

        // Owner posts moment
        MvcResult postResult = mockMvc.perform(post("/api/v1/feed")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"text\":\"Владелец пишет\"}"))
                .andExpect(status().isOk())
                .andReturn();

        String momentId = objectMapper.readTree(postResult.getResponse().getContentAsString())
                .path("data").path("id").asText();

        // Child tries to delete → 403
        mockMvc.perform(delete("/api/v1/feed/" + momentId)
                        .header(HttpHeaders.AUTHORIZATION, child.bearer()))
                .andExpect(status().isForbidden());
    }

    // -------------------------------------------------------------------------
    // OWNER can delete a member's moment
    // -------------------------------------------------------------------------

    @Test
    void ownerCanDeleteAnyMoment() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser("Алия");
        TestAuth.AuthedUser member = testAuth.createUser("Ержан");
        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(member.id(), new JoinHouseholdRequest(code));

        // Member posts moment
        MvcResult postResult = mockMvc.perform(post("/api/v1/feed")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"text\":\"Момент участника\"}"))
                .andExpect(status().isOk())
                .andReturn();

        String momentId = objectMapper.readTree(postResult.getResponse().getContentAsString())
                .path("data").path("id").asText();

        // Owner deletes member's moment → 200
        mockMvc.perform(delete("/api/v1/feed/" + momentId)
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk());

        // Moment gone
        mockMvc.perform(get("/api/v1/feed")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == '" + momentId + "')]").doesNotExist());
    }

    // -------------------------------------------------------------------------
    // GUEST cannot post → 403
    // -------------------------------------------------------------------------

    @Test
    void guestCannotPost_returns403() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser("Алия");
        TestAuth.AuthedUser guest = testAuth.createUser("Гость");
        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(guest.id(), new JoinHouseholdRequest(code));
        householdService.changeRole(owner.id(), guest.id(), HouseholdRole.GUEST);

        mockMvc.perform(post("/api/v1/feed")
                        .header(HttpHeaders.AUTHORIZATION, guest.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"text\":\"Гость пишет\"}"))
                .andExpect(status().isForbidden());
    }

    // -------------------------------------------------------------------------
    // GUEST cannot like → 403
    // -------------------------------------------------------------------------

    @Test
    void guestCannotLike_returns403() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser("Алия");
        TestAuth.AuthedUser guest = testAuth.createUser("Гость");
        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(guest.id(), new JoinHouseholdRequest(code));
        householdService.changeRole(owner.id(), guest.id(), HouseholdRole.GUEST);

        // Owner posts a moment
        MvcResult postResult = mockMvc.perform(post("/api/v1/feed")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"text\":\"Можно лайкнуть?\"}"))
                .andExpect(status().isOk())
                .andReturn();

        String momentId = objectMapper.readTree(postResult.getResponse().getContentAsString())
                .path("data").path("id").asText();

        // Guest tries to like → 403
        mockMvc.perform(post("/api/v1/feed/" + momentId + "/like")
                        .header(HttpHeaders.AUTHORIZATION, guest.bearer()))
                .andExpect(status().isForbidden());
    }
}
