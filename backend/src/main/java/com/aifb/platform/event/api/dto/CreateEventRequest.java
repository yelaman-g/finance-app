package com.aifb.platform.event.api.dto;

import com.aifb.platform.event.domain.EventType;
import com.aifb.platform.event.domain.RecurFreq;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

public record CreateEventRequest(
        @NotBlank @Size(max = 200) String title,
        @Size(max = 2000) String description,
        @NotNull LocalDate startDate,
        LocalTime startTime,
        boolean allDay,
        EventType type,
        RecurFreq recurFreq,
        Integer recurInterval,
        LocalDate recurUntil,
        BigDecimal budget,
        List<Integer> notifyDaysBefore,
        boolean shared) {
}
