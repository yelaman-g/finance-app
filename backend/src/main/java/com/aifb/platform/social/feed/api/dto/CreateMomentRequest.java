package com.aifb.platform.social.feed.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateMomentRequest(
        @NotBlank @Size(max = 2000) String text
) {}
