package com.aifb.platform.finance.goal.api.dto;

import com.aifb.platform.finance.goal.domain.GoalContribution;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public record ContributionResponse(
        UUID id,
        UUID goalId,
        BigDecimal amount,
        String note,
        LocalDate contributedOn) {

    public static ContributionResponse from(GoalContribution c) {
        return new ContributionResponse(
                c.getId(), c.getGoalId(), c.getAmount(), c.getNote(), c.getContributedOn());
    }
}
