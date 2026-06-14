package com.aifb.platform.social.reaction.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ReactRequest(
        @NotBlank @Size(max = 16) String emoji
) {
}
