package com.aifb.platform.ai.api.dto;
import jakarta.validation.constraints.NotBlank;
public record ChatTurnDto(@NotBlank String role, @NotBlank String content) {}
