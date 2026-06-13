package com.aifb.platform.ai.api.dto;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;
public record SavingsPlanRequest(
        @NotBlank String eventName,
        @NotNull LocalDate eventDate,
        @NotNull @DecimalMin("0.01") BigDecimal targetAmount,
        BigDecimal savedAmount) {}
