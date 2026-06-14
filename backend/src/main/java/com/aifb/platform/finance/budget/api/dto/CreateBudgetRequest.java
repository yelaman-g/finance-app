package com.aifb.platform.finance.budget.api.dto;

import com.aifb.platform.finance.budget.domain.BudgetTargetType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.UUID;

public record CreateBudgetRequest(
        @NotNull BudgetTargetType targetType,
        UUID categoryId,
        UUID groupId,
        @NotNull @DecimalMin(value = "0.01") @Digits(integer = 13, fraction = 2) BigDecimal amount,
        boolean shared,
        @Min(1) @Max(100) Integer notifyThresholdPercent) {
}
