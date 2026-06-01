package com.aifb.platform.finance.goal.service;

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

    public GoalService(GoalRepository goalRepository,
                       GoalContributionRepository contributionRepository) {
        this.goalRepository = goalRepository;
        this.contributionRepository = contributionRepository;
    }

    @Transactional(readOnly = true)
    public List<GoalResponse> list(UUID userId) {
        List<Goal> goals = goalRepository.findByUserIdOrderByCreatedAtDesc(userId);
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
        Goal goal = ownedGoal(userId, goalId);
        return GoalResponse.from(goal, contributionRepository.sumByGoalId(goalId));
    }

    @Transactional
    public GoalResponse create(UUID userId, CreateGoalRequest req) {
        Goal goal = new Goal(userId, req.name(), req.targetAmount(),
                req.deadline(), req.icon(), req.color());
        return GoalResponse.from(goalRepository.save(goal), BigDecimal.ZERO);
    }

    @Transactional
    public GoalResponse update(UUID userId, UUID goalId, UpdateGoalRequest req) {
        Goal goal = ownedGoal(userId, goalId);
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
        Goal goal = ownedGoal(userId, goalId);
        goalRepository.delete(goal);
    }

    @Transactional(readOnly = true)
    public List<ContributionResponse> listContributions(UUID userId, UUID goalId) {
        ownedGoal(userId, goalId);
        return contributionRepository.findByGoalIdOrderByContributedOnDesc(goalId).stream()
                .map(ContributionResponse::from)
                .toList();
    }

    @Transactional
    public ContributionResponse addContribution(UUID userId, UUID goalId, CreateContributionRequest req) {
        Goal goal = ownedGoal(userId, goalId);
        GoalContribution contribution = new GoalContribution(
                goalId, req.amount(), req.note(), req.contributedOn());
        contributionRepository.save(contribution);
        goal.recomputeStatus(contributionRepository.sumByGoalId(goalId));
        goalRepository.save(goal);
        return ContributionResponse.from(contribution);
    }

    @Transactional
    public void deleteContribution(UUID userId, UUID goalId, UUID contributionId) {
        Goal goal = ownedGoal(userId, goalId);
        GoalContribution contribution = contributionRepository.findByIdAndGoalId(contributionId, goalId)
                .orElseThrow(() -> new NotFoundException("Взнос не найден"));
        contributionRepository.delete(contribution);
        goal.recomputeStatus(contributionRepository.sumByGoalId(goalId));
        goalRepository.save(goal);
    }

    private Goal ownedGoal(UUID userId, UUID goalId) {
        return goalRepository.findByIdAndUserId(goalId, userId)
                .orElseThrow(() -> new NotFoundException("Цель не найдена"));
    }
}
