package com.aifb.platform.ai.api.dto;

import java.time.LocalDate;
import java.util.List;

public record DigestResponse(
        String tipOfDay,
        String narrative,
        List<String> highlights,
        List<DigestEvent> upcomingEvents
) {
    public record DigestEvent(String title, LocalDate date) {}
}
