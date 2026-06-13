package com.aifb.platform.event.api.dto;

import com.aifb.platform.event.domain.Event;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

public record EventResponse(
        UUID id, String title, String description, LocalDate startDate, LocalTime startTime,
        boolean allDay, String type, String recurFreq, int recurInterval, LocalDate recurUntil,
        boolean shared, UUID aiReminderId) {

    public static EventResponse from(Event e) {
        return new EventResponse(e.getId(), e.getTitle(), e.getDescription(), e.getStartDate(),
                e.getStartTime(), e.isAllDay(), e.getType().name(), e.getRecurFreq().name(),
                e.getRecurInterval(), e.getRecurUntil(), e.isShared(), e.getAiReminderId());
    }
}
