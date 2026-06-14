package com.aifb.platform.social.capsule;

import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.domain.HouseholdRole;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdService;
import com.aifb.platform.social.capsule.domain.TimeCapsule;
import com.aifb.platform.social.capsule.repository.TimeCapsuleRepository;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MvcResult;

import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class CapsuleApiIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired ObjectMapper objectMapper;
    @Autowired HouseholdService householdService;
    @Autowired HouseholdContextService householdContextService;
    @Autowired TimeCapsuleRepository timeCapsuleRepository;

    // -------------------------------------------------------------------------
    // Auth required
    // -------------------------------------------------------------------------

    @Test
    void authRequired_list() throws Exception {
        mockMvc.perform(get("/api/v1/capsules"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void authRequired_create() throws Exception {
        mockMvc.perform(post("/api/v1/capsules")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"T\",\"message\":\"M\",\"openDate\":\"2099-01-01\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void authRequired_delete() throws Exception {
        mockMvc.perform(delete("/api/v1/capsules/" + UUID.randomUUID()))
                .andExpect(status().isUnauthorized());
    }

    // -------------------------------------------------------------------------
    // Create with future open_date → locked=true, message null for any member
    // -------------------------------------------------------------------------

    @Test
    void createFutureCapsule_appearsLockedForAllMembers() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser member = testAuth.createUser();
        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(member.id(), new JoinHouseholdRequest(code));

        String body = objectMapper.writeValueAsString(Map.of(
                "title", "Письмо Арману",
                "message", "Секретное сообщение",
                "openDate", "2099-06-01"
        ));

        MvcResult createResult = mockMvc.perform(post("/api/v1/capsules")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("Письмо Арману"))
                .andExpect(jsonPath("$.data.locked").value(true))
                .andExpect(jsonPath("$.data.message").doesNotExist())
                .andReturn();

        String capsuleId = objectMapper.readTree(createResult.getResponse().getContentAsString())
                .path("data").path("id").asText();

        // Owner sees locked
        mockMvc.perform(get("/api/v1/capsules")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == '" + capsuleId + "')].locked").value(true))
                .andExpect(jsonPath("$.data[?(@.id == '" + capsuleId + "')].message").doesNotExist());

        // Other family member also sees locked, message null
        mockMvc.perform(get("/api/v1/capsules")
                        .header(HttpHeaders.AUTHORIZATION, member.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == '" + capsuleId + "')].locked").value(true))
                .andExpect(jsonPath("$.data[?(@.id == '" + capsuleId + "')].message").doesNotExist());
    }

    // -------------------------------------------------------------------------
    // Delete by creator works; delete by non-creator non-manager → 403
    // -------------------------------------------------------------------------

    @Test
    void deleteByCreator_works() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        householdService.create(owner.id(), new CreateHouseholdRequest("Семья"));

        String body = objectMapper.writeValueAsString(Map.of(
                "title", "Моя капсула",
                "message", "Текст",
                "openDate", "2099-01-01"
        ));

        MvcResult createResult = mockMvc.perform(post("/api/v1/capsules")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andReturn();

        String capsuleId = objectMapper.readTree(createResult.getResponse().getContentAsString())
                .path("data").path("id").asText();

        mockMvc.perform(delete("/api/v1/capsules/" + capsuleId)
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk());

        // Gone from list
        mockMvc.perform(get("/api/v1/capsules")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == '" + capsuleId + "')]").isEmpty());
    }

    @Test
    void deleteByNonCreatorNonManager_returns403() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser child = testAuth.createUser();
        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(child.id(), new JoinHouseholdRequest(code));
        householdService.changeRole(owner.id(), child.id(), HouseholdRole.CHILD);

        String body = objectMapper.writeValueAsString(Map.of(
                "title", "Владельца",
                "message", "Нельзя трогать",
                "openDate", "2099-01-01"
        ));

        MvcResult createResult = mockMvc.perform(post("/api/v1/capsules")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andReturn();

        String capsuleId = objectMapper.readTree(createResult.getResponse().getContentAsString())
                .path("data").path("id").asText();

        mockMvc.perform(delete("/api/v1/capsules/" + capsuleId)
                        .header(HttpHeaders.AUTHORIZATION, child.bearer()))
                .andExpect(status().isForbidden());
    }

    // -------------------------------------------------------------------------
    // GUEST cannot create → 403
    // -------------------------------------------------------------------------

    @Test
    void guestCannotCreate_returns403() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        TestAuth.AuthedUser guest = testAuth.createUser();
        String code = householdService.create(owner.id(), new CreateHouseholdRequest("Семья")).inviteCode();
        householdService.join(guest.id(), new JoinHouseholdRequest(code));
        householdService.changeRole(owner.id(), guest.id(), HouseholdRole.GUEST);

        String body = objectMapper.writeValueAsString(Map.of(
                "title", "Гость создаёт",
                "message", "Запрещено",
                "openDate", "2099-01-01"
        ));

        mockMvc.perform(post("/api/v1/capsules")
                        .header(HttpHeaders.AUTHORIZATION, guest.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isForbidden());
    }

    // -------------------------------------------------------------------------
    // Past/today open_date → 400
    // -------------------------------------------------------------------------

    @Test
    void pastOpenDate_returns400() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        householdService.create(owner.id(), new CreateHouseholdRequest("Семья"));

        String body = objectMapper.writeValueAsString(Map.of(
                "title", "Прошлая дата",
                "message", "Текст",
                "openDate", "2020-01-01"
        ));

        mockMvc.perform(post("/api/v1/capsules")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest());
    }

    @Test
    void todayOpenDate_returns400() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        householdService.create(owner.id(), new CreateHouseholdRequest("Семья"));

        String todayStr = LocalDate.now().toString();

        String body = objectMapper.writeValueAsString(Map.of(
                "title", "Сегодняшняя дата",
                "message", "Текст",
                "openDate", todayStr
        ));

        mockMvc.perform(post("/api/v1/capsules")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest());
    }

    // -------------------------------------------------------------------------
    // Revealed: insert past-dated capsule directly → GET shows locked=false, message visible
    // -------------------------------------------------------------------------

    @Test
    void pastDatedCapsule_isRevealed() throws Exception {
        TestAuth.AuthedUser owner = testAuth.createUser();
        householdService.create(owner.id(), new CreateHouseholdRequest("Семья"));

        // Get householdId directly via HouseholdContextService
        UUID householdId = householdContextService.membershipOrNull(owner.id()).householdId();

        // Insert past-dated capsule bypassing @Future DTO validation
        TimeCapsule pastCapsule = new TimeCapsule(
                householdId, owner.id(), "Прошлая капсула", "secret", LocalDate.now().minusDays(1));
        timeCapsuleRepository.save(pastCapsule);
        String capsuleId = pastCapsule.getId().toString();

        mockMvc.perform(get("/api/v1/capsules")
                        .header(HttpHeaders.AUTHORIZATION, owner.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == '" + capsuleId + "')].locked").value(false))
                .andExpect(jsonPath("$.data[?(@.id == '" + capsuleId + "')].message").value("secret"));
    }
}
