package com.aifb.platform.social.poll.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

public record CreatePollRequest(
        @NotBlank @Size(max = 300) String question,
        @NotNull @Size(min = 2, max = 10) List<@NotBlank String> options
) {}
