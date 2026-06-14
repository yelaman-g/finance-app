package com.aifb.platform.social.poll;

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

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class PollApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired ObjectMapper objectMapper;
    @Autowired HouseholdService householdService;

    // -------------------------------------------------------------------------
    // Auth required
    // -------------------------------------------------------------------------

    @Test
    void authRequired_list() throws Exception {
        mockMvc.perform(get("/api/v1/polls"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void authRequired_create() throws Exception {
        mockMvc.perform(post("/api/v1/polls")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"question\":\"Q?\",\"options\":[\"A\",\"B\"]}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void authRequired_vote() throws Exception {
        mockMvc.perform(post("/api/v1/polls/" + UUID.randomUUID() + "/vote")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"optionId\":\"" + UUID.randomUUID() + "\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void authRequired_close() throws Exception {
        mockMvc.perform(post("/api/v1/polls/" + UUID.randomUUID() + "/close"))
                .andExpect(status().isUnauthorized());
    }

    // -------------------------------------------------------------------------
    // Create poll → GET lists it with options, votes=0
    // -------------------------------------------------------------------------

    @Test
    void createPoll_listedWithZeroVotes() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        householdService.create(owner.id(), new CreateHouseholdRequest("Семья"));

        String body = objectMapper.writeValueAsString(Map.of(
                "question", "Куда едем в отпуск?",
                "options", List.of("Алматы", "Астана", "Шымкент")
        ));

        MvcResult createResult = mockMvc.perform(post("/api/v1/polls")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.question").value("Куда едем в отпуск?"))
                .andExpect(jsonPath("$.data.closed").value(false))
                .andExpect(jsonPath("$.data.options", hasSize(3)))
                .andExpect(jsonPath("$.data.options[0].text").value("Алматы"))
                .andExpect(jsonPath("$.data.options[0].votes").value(0))
                .andReturn();

        String pollId = objectMapper.readTree(createResult.getResponse().getContentAsString())
                .path("data").path("id").asText();

        mockMvc.perform(get("/api/v1/polls")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == '" + pollId + "')]").exists())
                .andExpect(jsonPath("$.data[?(@.id == '" + pollId + "')].options[0].votes").value(0));
    }

    // -------------------------------------------------------------------------
    // Member votes → count incremented, myVoteOptionId shown; no voter identities leaked
    // -------------------------------------------------------------------------

    @Test
    void memberVotes_countIncrementedAndAnonymous() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser member = testAuth.createUser();
        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(member.id(), new JoinHouseholdRequest(code));

        // Create poll
        String createBody = objectMapper.writeValueAsString(Map.of(
                "question", "Ужин?",
                "options", List.of("Пицца", "Суши")
        ));
        MvcResult createResult = mockMvc.perform(post("/api/v1/polls")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createBody))
                .andExpect(status().isOk())
                .andReturn();

        var pollNode = objectMapper.readTree(createResult.getResponse().getContentAsString()).path("data");
        String pollId = pollNode.path("id").asText();
        String optionId = pollNode.path("options").get(0).path("id").asText(); // "Пицца"

        // Member votes for Пицца
        mockMvc.perform(post("/api/v1/polls/" + pollId + "/vote")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"optionId\":\"" + optionId + "\"}"))
                .andExpect(status().isOk());

        // GET by member: votes=1 for Пицца, myVoteOptionId = that option
        mockMvc.perform(get("/api/v1/polls")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == '" + pollId + "')].options[?(@.id == '" + optionId + "')].votes").value(1))
                .andExpect(jsonPath("$.data[?(@.id == '" + pollId + "')].myVoteOptionId").value(optionId));

        // Assert anonymity: response must NOT have per-voter fields (userId in options is absent)
        String responseBody = mockMvc.perform(get("/api/v1/polls")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        // The poll's options must not contain userId fields
        var pollData = objectMapper.readTree(responseBody).path("data");
        for (var poll : pollData) {
            if (poll.path("id").asText().equals(pollId)) {
                for (var opt : poll.path("options")) {
                    assert !opt.has("voters") : "Options must not expose voter list";
                    assert !opt.has("userIds") : "Options must not expose voter ids";
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // Changing vote moves count: vote A then B → A=0, B=1
    // -------------------------------------------------------------------------

    @Test
    void changeVote_movesCount() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        householdService.create(owner.id(), new CreateHouseholdRequest("Семья"));

        String createBody = objectMapper.writeValueAsString(Map.of(
                "question", "Что смотрим?",
                "options", List.of("Фильм A", "Фильм B")
        ));
        MvcResult createResult = mockMvc.perform(post("/api/v1/polls")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createBody))
                .andExpect(status().isOk())
                .andReturn();

        var pollNode = objectMapper.readTree(createResult.getResponse().getContentAsString()).path("data");
        String pollId = pollNode.path("id").asText();
        String optA = pollNode.path("options").get(0).path("id").asText();
        String optB = pollNode.path("options").get(1).path("id").asText();

        // Vote for A
        mockMvc.perform(post("/api/v1/polls/" + pollId + "/vote")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"optionId\":\"" + optA + "\"}"))
                .andExpect(status().isOk());

        // Change vote to B
        mockMvc.perform(post("/api/v1/polls/" + pollId + "/vote")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"optionId\":\"" + optB + "\"}"))
                .andExpect(status().isOk());

        // Now A=0, B=1, total=1
        mockMvc.perform(get("/api/v1/polls")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == '" + pollId + "')].options[?(@.id == '" + optA + "')].votes").value(0))
                .andExpect(jsonPath("$.data[?(@.id == '" + pollId + "')].options[?(@.id == '" + optB + "')].votes").value(1))
                .andExpect(jsonPath("$.data[?(@.id == '" + pollId + "')].myVoteOptionId").value(optB));
    }

    // -------------------------------------------------------------------------
    // Voting on closed poll → 400
    // -------------------------------------------------------------------------

    @Test
    void votingOnClosedPoll_returns400() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        householdService.create(owner.id(), new CreateHouseholdRequest("Семья"));

        String createBody = objectMapper.writeValueAsString(Map.of(
                "question", "Закрытый опрос?",
                "options", List.of("Да", "Нет")
        ));
        MvcResult createResult = mockMvc.perform(post("/api/v1/polls")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createBody))
                .andExpect(status().isOk())
                .andReturn();

        var pollNode = objectMapper.readTree(createResult.getResponse().getContentAsString()).path("data");
        String pollId = pollNode.path("id").asText();
        String optId = pollNode.path("options").get(0).path("id").asText();

        // Close poll
        mockMvc.perform(post("/api/v1/polls/" + pollId + "/close")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk());

        // Try to vote → 400
        mockMvc.perform(post("/api/v1/polls/" + pollId + "/vote")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"optionId\":\"" + optId + "\"}"))
                .andExpect(status().isBadRequest());
    }

    // -------------------------------------------------------------------------
    // Creator can close poll
    // -------------------------------------------------------------------------

    @Test
    void creatorClosePoll_works() throws Exception {
        TestAuth.AuthedUser creator = testAuth.createUser();
        householdService.create(creator.id(), new CreateHouseholdRequest("Семья"));

        String createBody = objectMapper.writeValueAsString(Map.of(
                "question", "Закрыть?",
                "options", List.of("Да", "Нет")
        ));
        MvcResult createResult = mockMvc.perform(post("/api/v1/polls")
                        .header(HttpHeaders.AUTHORIZATION, creator.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createBody))
                .andExpect(status().isOk())
                .andReturn();

        String pollId = objectMapper.readTree(createResult.getResponse().getContentAsString())
                .path("data").path("id").asText();

        mockMvc.perform(post("/api/v1/polls/" + pollId + "/close")
                        .header(HttpHeaders.AUTHORIZATION, creator.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.closed").value(true));
    }

    // -------------------------------------------------------------------------
    // Random non-creator non-manager member cannot close → 403
    // -------------------------------------------------------------------------

    @Test
    void randomMemberCannotClose_returns403() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser randomMember = testAuth.createUser();
        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(randomMember.id(), new JoinHouseholdRequest(code));
        // Ensure randomMember is a regular ADULT or USER (not OWNER) - default join is ADULT
        // Downgrade to a role that cannot manage - we need a non-OWNER, non-ADULT
        // Actually join default is ADULT which has canManageSharedContent = true,
        // so we need a CHILD role. Let's check if there is one.
        // Looking at HouseholdRole: OWNER, ADULT, CHILD, GUEST
        householdService.changeRole(owner.id(), randomMember.id(), HouseholdRole.CHILD);

        String createBody = objectMapper.writeValueAsString(Map.of(
                "question", "Может CHILD закрыть?",
                "options", List.of("Да", "Нет")
        ));
        MvcResult createResult = mockMvc.perform(post("/api/v1/polls")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createBody))
                .andExpect(status().isOk())
                .andReturn();

        String pollId = objectMapper.readTree(createResult.getResponse().getContentAsString())
                .path("data").path("id").asText();

        mockMvc.perform(post("/api/v1/polls/" + pollId + "/close")
                        .header(HttpHeaders.AUTHORIZATION, randomMember.bearer()))
                .andExpect(status().isForbidden());
    }

    // -------------------------------------------------------------------------
    // GUEST cannot create poll → 403
    // -------------------------------------------------------------------------

    @Test
    void guestCannotCreatePoll_returns403() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser guest = testAuth.createUser();
        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(guest.id(), new JoinHouseholdRequest(code));
        householdService.changeRole(owner.id(), guest.id(), HouseholdRole.GUEST);

        String body = objectMapper.writeValueAsString(Map.of(
                "question", "Гость создаёт опрос?",
                "options", List.of("Да", "Нет")
        ));

        mockMvc.perform(post("/api/v1/polls")
                        .header(HttpHeaders.AUTHORIZATION, guest.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isForbidden());
    }

    // -------------------------------------------------------------------------
    // GUEST cannot vote → 403
    // -------------------------------------------------------------------------

    @Test
    void guestCannotVote_returns403() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser guest = testAuth.createUser();
        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(guest.id(), new JoinHouseholdRequest(code));
        householdService.changeRole(owner.id(), guest.id(), HouseholdRole.GUEST);

        // Create poll as owner
        String createBody = objectMapper.writeValueAsString(Map.of(
                "question", "Голосует гость?",
                "options", List.of("Да", "Нет")
        ));
        MvcResult createResult = mockMvc.perform(post("/api/v1/polls")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createBody))
                .andExpect(status().isOk())
                .andReturn();

        var pollNode = objectMapper.readTree(createResult.getResponse().getContentAsString()).path("data");
        String pollId = pollNode.path("id").asText();
        String optId = pollNode.path("options").get(0).path("id").asText();

        // Guest tries to vote → 403
        mockMvc.perform(post("/api/v1/polls/" + pollId + "/vote")
                        .header(HttpHeaders.AUTHORIZATION, guest.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"optionId\":\"" + optId + "\"}"))
                .andExpect(status().isForbidden());
    }

    // -------------------------------------------------------------------------
    // Create with fewer than 2 options → 400
    // -------------------------------------------------------------------------

    @Test
    void createWithLessThan2Options_returns400() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        householdService.create(owner.id(), new CreateHouseholdRequest("Семья"));

        String body = objectMapper.writeValueAsString(Map.of(
                "question", "Один вариант?",
                "options", List.of("Только один")
        ));

        mockMvc.perform(post("/api/v1/polls")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest());
    }
}
