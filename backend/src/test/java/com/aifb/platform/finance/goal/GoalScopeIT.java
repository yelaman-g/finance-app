package com.aifb.platform.finance.goal;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.finance.goal.api.dto.CreateContributionRequest;
import com.aifb.platform.finance.goal.api.dto.CreateGoalRequest;
import com.aifb.platform.finance.goal.api.dto.GoalResponse;
import com.aifb.platform.finance.goal.service.GoalService;
import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.domain.HouseholdRole;
import com.aifb.platform.household.service.HouseholdService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class GoalScopeIT extends AbstractIntegrationTest {

    @Autowired GoalService service;
    @Autowired HouseholdService householdService;
    @Autowired TestAuth testAuth;

    @Test
    void sharedGoalVisibleToFamilyAndContributable() {
        UUID owner = testAuth.createUser().id();
        UUID member = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(member, new JoinHouseholdRequest(code));

        GoalResponse goal = service.create(owner, new CreateGoalRequest(
                "Отпуск", new BigDecimal("1000.00"), LocalDate.now().plusMonths(3), null, null, true));
        assertThat(goal.shared()).isTrue();
        assertThat(service.list(member, Scope.FAMILY)).anyMatch(g -> g.id().equals(goal.id()));

        service.addContribution(member, goal.id(),
                new CreateContributionRequest(new BigDecimal("400.00"), null, LocalDate.now()));
        assertThat(service.get(owner, goal.id()).savedAmount()).isEqualByComparingTo("400.00");
    }

    @Test
    void childCannotCreateSharedGoal() {
        UUID owner = testAuth.createUser().id();
        UUID child = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(child, new JoinHouseholdRequest(code));
        householdService.changeRole(owner, child, HouseholdRole.CHILD);
        assertThatThrownBy(() -> service.create(child, new CreateGoalRequest(
                "X", new BigDecimal("100.00"), null, null, null, true)))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void personalGoalsExcludeShared() {
        UUID owner = testAuth.createUser().id();
        householdService.create(owner, new CreateHouseholdRequest("С"));
        GoalResponse shared = service.create(owner, new CreateGoalRequest(
                "Общая", new BigDecimal("500.00"), null, null, null, true));
        GoalResponse personal = service.create(owner, new CreateGoalRequest(
                "Личная", new BigDecimal("500.00"), null, null, null, false));
        assertThat(service.list(owner, Scope.PERSONAL)).anyMatch(g -> g.id().equals(personal.id()))
                .noneMatch(g -> g.id().equals(shared.id()));
    }
}
