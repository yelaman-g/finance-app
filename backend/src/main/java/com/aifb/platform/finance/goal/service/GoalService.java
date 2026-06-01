package com.aifb.platform.finance.goal.service;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.goal.api.dto.ContributionResponse;
import com.aifb.platform.finance.goal.api.dto.CreateContributionRequest;
import com.aifb.platform.finance.goal.api.dto.CreateGoalRequest;
import com.aifb.platform.finance.goal.api.dto.GoalResponse;
import com.aifb.platform.finance.goal.api.dto.UpdateGoalRequest;
import com.aifb.platform.finance.goal.domain.Goal;
import com.aifb.platform.finance.goal.domain.GoalContribution;
import com.aifb.platform.finance.goal.repository.GoalContributionRepository;
import com.aifb.platform.finance.goal.repository.GoalRepository;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class GoalService {

    private final GoalRepository goalRepository;
    private final GoalContributionRepository contributionRepository;
    private final HouseholdContextService householdContext;

    public GoalService(GoalRepository goalRepository,
                       GoalContributionRepository contributionRepository,
                       HouseholdContextService householdContext) {
        this.goalRepository = goalRepository;
        this.contributionRepository = contributionRepository;
        this.householdContext = householdContext;
    }

    @Transactional(readOnly = true)
    public List<GoalResponse> list(UUID userId, Scope scope) {
        List<Goal> goals;
        if (scope == Scope.FAMILY) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            goals = ctx == null ? List.of()
                    : goalRepository.findByHouseholdIdOrderByCreatedAtDesc(ctx.householdId());
        } else {
            goals = goalRepository.findByUserIdAndHouseholdIdIsNullOrderByCreatedAtDesc(userId);
        }
        if (goals.isEmpty()) {
            return List.of();
        }
        Map<UUID, BigDecimal> sums = contributionRepository.sumByGoalIds(
                        goals.stream().map(Goal::getId).toList())
                .stream().collect(Collectors.toMap(
                        GoalContributionRepository.GoalSum::getGoalId,
                        GoalContributionRepository.GoalSum::getTotal));
        return goals.stream()
                .map(g -> GoalResponse.from(g, sums.getOrDefault(g.getId(), BigDecimal.ZERO)))
                .toList();
    }

    @Transactional(readOnly = true)
    public GoalResponse get(UUID userId, UUID goalId) {
        Goal goal = accessibleGoal(userId, goalId);
        return GoalResponse.from(goal, contributionRepository.sumByGoalId(goalId));
    }

    @Transactional
    public GoalResponse create(UUID userId, CreateGoalRequest req) {
        Goal goal = new Goal(userId, req.name(), req.targetAmount(),
                req.deadline(), req.icon(), req.color());
        if (req.shared()) {
            HouseholdContext ctx = householdContext.requireManageSharedContent(userId);
            goal.assignHousehold(ctx.householdId());
        }
        return GoalResponse.from(goalRepository.save(goal), BigDecimal.ZERO);
    }

    @Transactional
    public GoalResponse update(UUID userId, UUID goalId, UpdateGoalRequest req) {
        Goal goal = manageableGoal(userId, goalId);
        goal.setName(req.name());
        goal.setTargetAmount(req.targetAmount());
        goal.setDeadline(req.deadline());
        goal.setIcon(req.icon());
        goal.setColor(req.color());
        BigDecimal saved = contributionRepository.sumByGoalId(goalId);
        goal.recomputeStatus(saved);
        return GoalResponse.from(goalRepository.save(goal), saved);
    }

    @Transactional
    public void delete(UUID userId, UUID goalId) {
        Goal goal = manageableGoal(userId, goalId);
        goalRepository.delete(goal);
    }

    @Transactional(readOnly = true)
    public List<ContributionResponse> listContributions(UUID userId, UUID goalId) {
        accessibleGoal(userId, goalId);
        return contributionRepository.findByGoalIdOrderByContributedOnDesc(goalId).stream()
                .map(ContributionResponse::from)
                .toList();
    }

    @Transactional
    public ContributionResponse addContribution(UUID userId, UUID goalId, CreateContributionRequest req) {
        Goal goal = manageableGoal(userId, goalId);
        GoalContribution contribution = new GoalContribution(
                goalId, req.amount(), req.note(), req.contributedOn());
        contributionRepository.save(contribution);
        goal.recomputeStatus(contributionRepository.sumByGoalId(goalId));
        goalRepository.save(goal);
        return ContributionResponse.from(contribution);
    }

    @Transactional
    public void deleteContribution(UUID userId, UUID goalId, UUID contributionId) {
        Goal goal = manageableGoal(userId, goalId);
        GoalContribution contribution = contributionRepository.findByIdAndGoalId(contributionId, goalId)
                .orElseThrow(() -> new NotFoundException("Взнос не найден"));
        contributionRepository.delete(contribution);
        goal.recomputeStatus(contributionRepository.sumByGoalId(goalId));
        goalRepository.save(goal);
    }

    private Goal accessibleGoal(UUID userId, UUID goalId) {
        Goal goal = goalRepository.findById(goalId)
                .orElseThrow(() -> new NotFoundException("Цель не найдена"));
        if (goal.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null || !ctx.householdId().equals(goal.getHouseholdId())) {
                throw new NotFoundException("Цель не найдена");
            }
            return goal;
        }
        if (!userId.equals(goal.getUserId())) {
            throw new NotFoundException("Цель не найдена");
        }
        return goal;
    }

    private Goal manageableGoal(UUID userId, UUID goalId) {
        Goal goal = accessibleGoal(userId, goalId);
        if (goal.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null || !ctx.canManageSharedContent()) {
                throw new ForbiddenException("Недостаточно прав для семейной цели");
            }
        }
        return goal;
    }
}
