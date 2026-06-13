package com.aifb.platform.ai.api.dto;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
public record ReminderResponse(
        UUID id, String eventName, LocalDate eventDate,
        BigDecimal targetAmount, BigDecimal savedAmount, List<Integer> notifyDaysBefore,
        boolean isActive, boolean shared,
        long daysUntil, int monthsRemaining, BigDecimal monthlyNeeded, double progressPercent) {}
