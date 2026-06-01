package com.aifb.platform.finance.goal;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.goal.api.dto.ContributionResponse;
import com.aifb.platform.finance.goal.api.dto.CreateContributionRequest;
import com.aifb.platform.finance.goal.api.dto.CreateGoalRequest;
import com.aifb.platform.finance.goal.api.dto.GoalResponse;
import com.aifb.platform.finance.goal.api.dto.UpdateGoalRequest;
import com.aifb.platform.finance.goal.service.GoalService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class GoalServiceIT extends AbstractIntegrationTest {

    @Autowired GoalService service;
    @Autowired TestAuth testAuth;

    private GoalResponse newGoal(UUID userId, String target) {
        return service.create(userId, new CreateGoalRequest(
                "Отпуск", new BigDecimal(target), LocalDate.now().plusMonths(6), "beach", "#22AAFF", false));
    }

    @Test
    void createStartsActiveWithZeroProgress() {
        UUID userId = testAuth.createUser().id();
        GoalResponse goal = newGoal(userId, "1000.00");
        assertThat(goal.status()).isEqualTo("ACTIVE");
        assertThat(goal.savedAmount()).isEqualByComparingTo("0");
        assertThat(goal.percentage()).isEqualTo(0.0);
    }

    @Test
    void contributionsIncreaseProgress() {
        UUID userId = testAuth.createUser().id();
        GoalResponse goal = newGoal(userId, "1000.00");

        service.addContribution(userId, goal.id(),
                new CreateContributionRequest(new BigDecimal("250.00"), "первый", LocalDate.now()));
        GoalResponse afterFirst = service.get(userId, goal.id());
        assertThat(afterFirst.savedAmount()).isEqualByComparingTo("250.00");
        assertThat(afterFirst.percentage()).isEqualTo(25.0);
        assertThat(afterFirst.status()).isEqualTo("ACTIVE");
    }

    @Test
    void reachingTargetMarksCompleted() {
        UUID userId = testAuth.createUser().id();
        GoalResponse goal = newGoal(userId, "500.00");
        service.addContribution(userId, goal.id(),
                new CreateContributionRequest(new BigDecimal("500.00"), null, LocalDate.now()));
        assertThat(service.get(userId, goal.id()).status()).isEqualTo("COMPLETED");
    }

    @Test
    void deletingContributionRevertsCompletion() {
        UUID userId = testAuth.createUser().id();
        GoalResponse goal = newGoal(userId, "500.00");
        ContributionResponse c = service.addContribution(userId, goal.id(),
                new CreateContributionRequest(new BigDecimal("500.00"), null, LocalDate.now()));
        assertThat(service.get(userId, goal.id()).status()).isEqualTo("COMPLETED");

        service.deleteContribution(userId, goal.id(), c.id());
        GoalResponse after = service.get(userId, goal.id());
        assertThat(after.savedAmount()).isEqualByComparingTo("0");
        assertThat(after.status()).isEqualTo("ACTIVE");
    }

    @Test
    void listReturnsGoalsWithProgress() {
        UUID userId = testAuth.createUser().id();
        GoalResponse goal = newGoal(userId, "1000.00");
        service.addContribution(userId, goal.id(),
                new CreateContributionRequest(new BigDecimal("100.00"), null, LocalDate.now()));
        assertThat(service.list(userId, Scope.PERSONAL))
                .anyMatch(g -> g.id().equals(goal.id())
                        && g.savedAmount().compareTo(new BigDecimal("100.00")) == 0);
    }

    @Test
    void updateChangesNameAndTarget() {
        UUID userId = testAuth.createUser().id();
        GoalResponse goal = newGoal(userId, "1000.00");
        GoalResponse updated = service.update(userId, goal.id(),
                new UpdateGoalRequest("Машина", new BigDecimal("2000.00"), null, "car", "#FF0000"));
        assertThat(updated.name()).isEqualTo("Машина");
        assertThat(updated.targetAmount()).isEqualByComparingTo("2000.00");
    }

    @Test
    void otherUserCannotAccessGoal() {
        UUID owner = testAuth.createUser().id();
        UUID other = testAuth.createUser().id();
        GoalResponse goal = newGoal(owner, "1000.00");
        assertThatThrownBy(() -> service.get(other, goal.id()))
                .isInstanceOf(NotFoundException.class);
        assertThatThrownBy(() -> service.addContribution(other, goal.id(),
                new CreateContributionRequest(new BigDecimal("10.00"), null, LocalDate.now())))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void deleteRemovesGoalAndContributions() {
        UUID userId = testAuth.createUser().id();
        GoalResponse goal = newGoal(userId, "1000.00");
        service.addContribution(userId, goal.id(),
                new CreateContributionRequest(new BigDecimal("100.00"), null, LocalDate.now()));
        service.delete(userId, goal.id());
        assertThat(service.list(userId, Scope.PERSONAL)).noneMatch(g -> g.id().equals(goal.id()));
    }
}
