package com.aifb.platform.finance.budget.api.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record BudgetResponse(
        UUID id, String targetType, UUID targetId, String targetName,
        BigDecimal amount, BigDecimal spent, double percentage, String status, boolean shared,
        int notifyThresholdPercent) {
}
