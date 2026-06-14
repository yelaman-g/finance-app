package com.aifb.platform.chat.api.dto;

import java.time.Instant;
import java.util.UUID;

public record ChatMessageResponse(
        UUID id,
        UUID householdId,
        UUID senderId,
        String senderName,
        String text,
        Instant createdAt
) {
}
