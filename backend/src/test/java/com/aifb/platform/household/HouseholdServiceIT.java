package com.aifb.platform.household;

import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.household.domain.HouseholdRole;
import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.HouseholdResponse;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.service.HouseholdService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class HouseholdServiceIT extends AbstractIntegrationTest {

    @Autowired HouseholdService service;
    @Autowired TestAuth testAuth;

    @Test
    void createMakesCallerOwnerWithInviteCode() {
        UUID userId = testAuth.createUser().id();
        HouseholdResponse h = service.create(userId, new CreateHouseholdRequest("Семья"));
        assertThat(h.myRole()).isEqualTo("OWNER");
        assertThat(h.inviteCode()).isNotBlank();
        assertThat(h.members()).hasSize(1);
    }

    @Test
    void createTwiceForSameUserConflicts() {
        UUID userId = testAuth.createUser().id();
        service.create(userId, new CreateHouseholdRequest("Семья"));
        assertThatThrownBy(() -> service.create(userId, new CreateHouseholdRequest("Вторая")))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void joinByCodeAddsAdultMember() {
        UUID owner = testAuth.createUser().id();
        UUID joiner = testAuth.createUser().id();
        String code = service.create(owner, new CreateHouseholdRequest("Семья")).inviteCode();

        HouseholdResponse joined = service.join(joiner, new JoinHouseholdRequest(code));
        assertThat(joined.myRole()).isEqualTo("ADULT");
        assertThat(joined.members()).hasSize(2);
    }

    @Test
    void joinWithBadCodeNotFound() {
        UUID joiner = testAuth.createUser().id();
        assertThatThrownBy(() -> service.join(joiner, new JoinHouseholdRequest("BADCODE0")))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void joinWhenAlreadyInHouseholdConflicts() {
        UUID owner = testAuth.createUser().id();
        UUID joiner = testAuth.createUser().id();
        String code = service.create(owner, new CreateHouseholdRequest("Семья")).inviteCode();
        service.join(joiner, new JoinHouseholdRequest(code));
        assertThatThrownBy(() -> service.join(joiner, new JoinHouseholdRequest(code)))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void getMineHidesInviteCodeFromNonOwner() {
        UUID owner = testAuth.createUser().id();
        UUID joiner = testAuth.createUser().id();
        String code = service.create(owner, new CreateHouseholdRequest("Семья")).inviteCode();
        service.join(joiner, new JoinHouseholdRequest(code));

        assertThat(service.getMine(owner).inviteCode()).isEqualTo(code);
        assertThat(service.getMine(joiner).inviteCode()).isNull();
        assertThat(service.getMine(joiner).myRole()).isEqualTo("ADULT");
    }

    @Test
    void getMineWithoutHouseholdNotFound() {
        UUID userId = testAuth.createUser().id();
        assertThatThrownBy(() -> service.getMine(userId))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void ownerChangesMemberRoleToChild() {
        UUID owner = testAuth.createUser().id();
        UUID joiner = testAuth.createUser().id();
        String code = service.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        service.join(joiner, new JoinHouseholdRequest(code));

        service.changeRole(owner, joiner, HouseholdRole.CHILD);
        assertThat(service.getMine(joiner).myRole()).isEqualTo("CHILD");
    }

    @Test
    void nonOwnerCannotChangeRole() {
        UUID owner = testAuth.createUser().id();
        UUID joiner = testAuth.createUser().id();
        String code = service.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        service.join(joiner, new JoinHouseholdRequest(code));
        assertThatThrownBy(() -> service.changeRole(joiner, owner, HouseholdRole.CHILD))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void ownerCannotChangeOwnRole() {
        UUID owner = testAuth.createUser().id();
        service.create(owner, new CreateHouseholdRequest("С"));
        assertThatThrownBy(() -> service.changeRole(owner, owner, HouseholdRole.ADULT))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void cannotPromoteToSecondOwner() {
        UUID owner = testAuth.createUser().id();
        UUID joiner = testAuth.createUser().id();
        String code = service.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        service.join(joiner, new JoinHouseholdRequest(code));
        assertThatThrownBy(() -> service.changeRole(owner, joiner, HouseholdRole.OWNER))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void ownerRemovesMember() {
        UUID owner = testAuth.createUser().id();
        UUID joiner = testAuth.createUser().id();
        String code = service.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        service.join(joiner, new JoinHouseholdRequest(code));

        service.removeMember(owner, joiner);
        assertThat(service.getMine(owner).members()).hasSize(1);
        assertThatThrownBy(() -> service.getMine(joiner)).isInstanceOf(NotFoundException.class);
    }

    @Test
    void memberLeaves() {
        UUID owner = testAuth.createUser().id();
        UUID joiner = testAuth.createUser().id();
        String code = service.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        service.join(joiner, new JoinHouseholdRequest(code));

        service.leave(joiner);
        assertThatThrownBy(() -> service.getMine(joiner)).isInstanceOf(NotFoundException.class);
        assertThat(service.getMine(owner).members()).hasSize(1);
    }

    @Test
    void ownerCannotLeaveMustDisband() {
        UUID owner = testAuth.createUser().id();
        service.create(owner, new CreateHouseholdRequest("С"));
        assertThatThrownBy(() -> service.leave(owner)).isInstanceOf(ForbiddenException.class);
    }

    @Test
    void ownerDisbandsHousehold() {
        UUID owner = testAuth.createUser().id();
        UUID joiner = testAuth.createUser().id();
        String code = service.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        service.join(joiner, new JoinHouseholdRequest(code));

        service.disband(owner);
        assertThatThrownBy(() -> service.getMine(owner)).isInstanceOf(NotFoundException.class);
        assertThatThrownBy(() -> service.getMine(joiner)).isInstanceOf(NotFoundException.class);
    }

    @Test
    void rotateCodeChangesInviteCode() {
        UUID owner = testAuth.createUser().id();
        String oldCode = service.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        String newCode = service.rotateCode(owner).inviteCode();
        assertThat(newCode).isNotEqualTo(oldCode).isNotBlank();
    }
}
