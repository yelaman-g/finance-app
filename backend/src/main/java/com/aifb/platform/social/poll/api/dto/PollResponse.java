package com.aifb.platform.social.poll.api.dto;

import java.util.List;
import java.util.UUID;

public record PollResponse(
        UUID id,
        String question,
        boolean closed,
        UUID createdBy,
        List<PollOptionResult> options,
        UUID myVoteOptionId
) {}
