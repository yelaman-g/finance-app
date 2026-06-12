package com.aifb.platform.auth.api.dto;

import jakarta.validation.constraints.NotBlank;

public record GoogleAuthRequest(
        @NotBlank(message = "idToken is required")
        String idToken) {
}
