package com.aifb.platform.social.capsule.api.dto;

import java.time.LocalDate;
import java.util.UUID;

public record CapsuleResponse(
        UUID id,
        String title,
        LocalDate openDate,
        boolean locked,
        String message,
        UUID createdBy
) {}
