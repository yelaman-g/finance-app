package com.aifb.platform.ai.api.dto;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
public record CreateReminderRequest(
        @NotBlank String eventName,
        @NotNull LocalDate eventDate,
        BigDecimal targetAmount,
        BigDecimal savedAmount,
        List<Integer> notifyDaysBefore,
        boolean shared) {}
