package com.aifb.platform.auth.api.dto;

public record AuthResponse(
        UserResponse user,
        TokenResponse tokens) {
}
