package com.aifb.platform.finance.category;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.finance.category.api.dto.CategoryResponse;
import com.aifb.platform.finance.category.api.dto.CreateCategoryRequest;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
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

class CategoryScopeIT extends AbstractIntegrationTest {

    @Autowired CategoryService service;
    @Autowired HouseholdService householdService;
    @Autowired TestAuth testAuth;

    @Test
    void sharedCategoryVisibleToFamilyNotPersonal() {
        UUID owner = testAuth.createUser().id();
        UUID member = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(member, new JoinHouseholdRequest(code));

        CategoryResponse shared = service.create(owner,
                new CreateCategoryRequest("Коммуналка", CategoryType.EXPENSE, null, null, true, null));
        assertThat(shared.shared()).isTrue();

        assertThat(service.list(owner, CategoryType.EXPENSE, Scope.FAMILY))
                .anyMatch(c -> c.id().equals(shared.id()));
        assertThat(service.list(member, CategoryType.EXPENSE, Scope.FAMILY))
                .anyMatch(c -> c.id().equals(shared.id()));
        assertThat(service.list(owner, CategoryType.EXPENSE, Scope.PERSONAL))
                .noneMatch(c -> c.id().equals(shared.id()));
    }

    @Test
    void childCannotCreateSharedCategory() {
        UUID owner = testAuth.createUser().id();
        UUID child = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(child, new JoinHouseholdRequest(code));
        householdService.changeRole(owner, child, HouseholdRole.CHILD);

        assertThatThrownBy(() -> service.create(child,
                new CreateCategoryRequest("X", CategoryType.EXPENSE, null, null, true, null)))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void sharedCreateWithoutHouseholdConflicts() {
        UUID solo = testAuth.createUser().id();
        assertThatThrownBy(() -> service.create(solo,
                new CreateCategoryRequest("X", CategoryType.EXPENSE, null, null, true, null)))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void adultCanDeleteSharedCategory() {
        UUID owner = testAuth.createUser().id();
        householdService.create(owner, new CreateHouseholdRequest("Семья"));
        CategoryResponse shared = service.create(owner,
                new CreateCategoryRequest("Коммуналка", CategoryType.EXPENSE, null, null, true, null));
        service.delete(owner, shared.id());
        assertThat(service.list(owner, CategoryType.EXPENSE, Scope.FAMILY))
                .noneMatch(c -> c.id().equals(shared.id()));
    }
}
