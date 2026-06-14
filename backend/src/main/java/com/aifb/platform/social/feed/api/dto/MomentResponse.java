package com.aifb.platform.social.feed.api.dto;

import java.time.Instant;
import java.util.UUID;

public record MomentResponse(
        UUID id,
        UUID authorId,
        String authorName,
        String text,
        Instant createdAt,
        long likes,
        boolean likedByMe
) {}
