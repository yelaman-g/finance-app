package com.aifb.platform.notification.api.dto;

import com.aifb.platform.notification.domain.DevicePlatform;
import jakarta.validation.constraints.NotBlank;

public record RegisterTokenRequest(
        @NotBlank String token,
        DevicePlatform platform) {}
