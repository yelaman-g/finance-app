package com.aifb.platform.finance.goal.api.dto;

import com.aifb.platform.finance.goal.domain.Goal;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.UUID;

public record GoalResponse(
        UUID id,
        String name,
        BigDecimal targetAmount,
        BigDecimal savedAmount,
        double percentage,
        LocalDate deadline,
        String status,
        String icon,
        String color,
        boolean shared) {

    public static GoalResponse from(Goal g, BigDecimal saved) {
        BigDecimal safeSaved = saved == null ? BigDecimal.ZERO : saved;
        double percentage = g.getTargetAmount().signum() == 0 ? 0.0
                : Math.min(100.0, safeSaved.multiply(BigDecimal.valueOf(100))
                    .divide(g.getTargetAmount(), 1, RoundingMode.HALF_UP).doubleValue());
        return new GoalResponse(
                g.getId(),
                g.getName(),
                g.getTargetAmount(),
                safeSaved,
                percentage,
                g.getDeadline(),
                g.getStatus().name(),
                g.getIcon(),
                g.getColor(),
                g.isShared());
    }
}
