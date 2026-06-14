package com.aifb.platform.social.poll.api.dto;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record VoteRequest(
        @NotNull UUID optionId
) {}
