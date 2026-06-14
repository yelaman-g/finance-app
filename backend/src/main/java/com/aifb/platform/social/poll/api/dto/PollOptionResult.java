package com.aifb.platform.social.poll.api.dto;

import java.util.UUID;

public record PollOptionResult(
        UUID id,
        String text,
        long votes
) {}
