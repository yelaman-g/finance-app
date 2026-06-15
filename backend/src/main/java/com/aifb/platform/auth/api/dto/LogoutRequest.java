package com.aifb.platform.auth.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record LogoutRequest(
        @NotBlank
        @Size(max = 512)
        String refreshToken) {
}
