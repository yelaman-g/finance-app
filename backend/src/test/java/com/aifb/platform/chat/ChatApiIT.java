package com.aifb.platform.chat;

import com.aifb.platform.chat.service.ChatService;
import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.domain.HouseholdRole;
import com.aifb.platform.household.service.HouseholdService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Integration tests for family chat REST history endpoint.
 * Verifies: auth, household scope, message ordering, GUEST send restriction.
 */
class ChatApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired HouseholdService householdService;
    @Autowired ChatService chatService;

    // ─── auth ───────────────────────────────────────────────────────────────

    @Test
    void getHistory_unauthenticated_returns401() throws Exception {
        mockMvc.perform(get("/api/v1/chat"))
                .andExpect(status().isUnauthorized());
    }

    // ─── scope ──────────────────────────────────────────────────────────────

    @Test
    void getHistory_ownerAndMemberBothSeeMessage_oldestFirst() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser("Иван");
        TestAuth.AuthedUser member = testAuth.createUser("Мария");

        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(member.id(), new JoinHouseholdRequest(code));

        chatService.send(owner.id(), "Привет!");
        chatService.send(member.id(), "Здравствуй!");

        // Both see the two messages in oldest-first order
        mockMvc.perform(get("/api/v1/chat")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(2))
                .andExpect(jsonPath("$.data[0].text").value("Привет!"))
                .andExpect(jsonPath("$.data[1].text").value("Здравствуй!"))
                .andExpect(jsonPath("$.data[0].senderName").value("Иван"));

        mockMvc.perform(get("/api/v1/chat")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(2));
    }

    @Test
    void getHistory_differentHouseholdMemberDoesNotSeeMessages() throws Exception {
        TestAuth.AuthedUser owner1 = testAuth.createUser("Семья1-Владелец");
        TestAuth.AuthedUser owner2 = testAuth.createUser("Семья2-Владелец");

        householdService.create(owner1.id(), new CreateHouseholdRequest("Семья1"));
        householdService.create(owner2.id(), new CreateHouseholdRequest("Семья2"));

        chatService.send(owner1.id(), "Секретное сообщение семьи 1");

        // owner2 is in a different household — must see 0 messages
        mockMvc.perform(get("/api/v1/chat")
                        .header(HttpHeaders.AUTHORIZATION, owner2.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(0));
    }

    @Test
    void getHistory_userWithoutHousehold_returnsEmptyList() throws Exception {
        TestAuth.AuthedUser loner = testAuth.createUser("Одиночка");

        mockMvc.perform(get("/api/v1/chat")
                        .header(HttpHeaders.AUTHORIZATION, loner.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(0));
    }

    // ─── guest restriction ───────────────────────────────────────────────────

    @Test
    void send_asGuest_throwsForbiddenException() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser("Владелец");
        TestAuth.AuthedUser guest = testAuth.createUser("Гость");

        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(guest.id(), new JoinHouseholdRequest(code));
        householdService.changeRole(owner.id(), guest.id(), HouseholdRole.GUEST);

        org.junit.jupiter.api.Assertions.assertThrows(
                com.aifb.platform.common.exception.ForbiddenException.class,
                () -> chatService.send(guest.id(), "Гость не может писать"));
    }
}
