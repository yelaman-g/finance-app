package com.aifb.platform.finance.goal.api.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;

public record UpdateGoalRequest(
        @NotBlank @Size(max = 120) String name,
        @NotNull @DecimalMin(value = "0.01") @Digits(integer = 13, fraction = 2) BigDecimal targetAmount,
        LocalDate deadline,
        @Size(max = 40) String icon,
        @Size(max = 9) String color) {
}
