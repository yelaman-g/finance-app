package com.aifb.platform.finance.budget.api.dto;

import java.math.BigDecimal;

public record BudgetWarning(
        String targetType, String targetName, BigDecimal amount,
        BigDecimal spent, double percentage, String status) {
}
