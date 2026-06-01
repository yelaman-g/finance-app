package com.aifb.platform.finance.group;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.group.api.dto.CreateGroupRequest;
import com.aifb.platform.finance.group.api.dto.GroupResponse;
import com.aifb.platform.finance.group.api.dto.UpdateGroupRequest;
import com.aifb.platform.finance.group.service.CategoryGroupService;
import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.domain.HouseholdRole;
import com.aifb.platform.household.service.HouseholdService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CategoryGroupServiceIT extends AbstractIntegrationTest {

    @Autowired CategoryGroupService service;
    @Autowired HouseholdService householdService;
    @Autowired TestAuth testAuth;

    @Test
    void createPersonalGroupVisibleOnlyToOwnerScope() {
        UUID userId = testAuth.createUser().id();
        GroupResponse g = service.create(userId,
                new CreateGroupRequest("Коммунальные", CategoryType.EXPENSE, "home", "#888888", false));
        assertThat(g.shared()).isFalse();
        assertThat(service.list(userId, CategoryType.EXPENSE, Scope.PERSONAL))
                .anyMatch(x -> x.id().equals(g.id()));
        assertThat(service.list(userId, CategoryType.EXPENSE, Scope.FAMILY)).isEmpty();
    }

    @Test
    void sharedGroupVisibleToFamily() {
        UUID owner = testAuth.createUser().id();
        UUID member = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(member, new JoinHouseholdRequest(code));
        GroupResponse g = service.create(owner,
                new CreateGroupRequest("Коммунальные", CategoryType.EXPENSE, null, null, true));
        assertThat(g.shared()).isTrue();
        assertThat(service.list(member, CategoryType.EXPENSE, Scope.FAMILY))
                .anyMatch(x -> x.id().equals(g.id()));
    }

    @Test
    void childCannotCreateSharedGroup() {
        UUID owner = testAuth.createUser().id();
        UUID child = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(child, new JoinHouseholdRequest(code));
        householdService.changeRole(owner, child, HouseholdRole.CHILD);
        assertThatThrownBy(() -> service.create(child,
                new CreateGroupRequest("X", CategoryType.EXPENSE, null, null, true)))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void sharedCreateWithoutHouseholdConflicts() {
        UUID solo = testAuth.createUser().id();
        assertThatThrownBy(() -> service.create(solo,
                new CreateGroupRequest("X", CategoryType.EXPENSE, null, null, true)))
                .isInstanceOf(com.aifb.platform.common.exception.ConflictException.class);
    }

    @Test
    void updateAndDeletePersonalGroup() {
        UUID userId = testAuth.createUser().id();
        GroupResponse g = service.create(userId,
                new CreateGroupRequest("Старое", CategoryType.EXPENSE, null, null, false));
        GroupResponse upd = service.update(userId, g.id(),
                new UpdateGroupRequest("Новое", "tag", "#111111"));
        assertThat(upd.name()).isEqualTo("Новое");
        service.delete(userId, g.id());
        assertThat(service.list(userId, CategoryType.EXPENSE, Scope.PERSONAL))
                .noneMatch(x -> x.id().equals(g.id()));
    }

    @Test
    void updateOthersGroupNotFound() {
        UUID owner = testAuth.createUser().id();
        UUID other = testAuth.createUser().id();
        GroupResponse g = service.create(owner,
                new CreateGroupRequest("Моя", CategoryType.EXPENSE, null, null, false));
        assertThatThrownBy(() -> service.update(other, g.id(),
                new UpdateGroupRequest("X", null, null)))
                .isInstanceOf(NotFoundException.class);
    }
}
