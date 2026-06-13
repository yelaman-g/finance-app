package com.aifb.platform.event.api.dto;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

public record EventOccurrenceResponse(
        UUID eventId, String title, String description, LocalDate date, LocalTime time,
        boolean allDay, String type, boolean recurring) {
}
