package com.aifb.platform.finance.categorization.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record CreateRuleRequest(
        @NotBlank @Size(max = 80) String keyword,
        @NotNull UUID categoryId) {
}
