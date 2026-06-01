package com.aifb.platform.finance.category.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record UpdateCategoryRequest(
        @NotBlank @Size(max = 80) String name,
        @Size(max = 40) String icon,
        @Size(max = 9) String color,
        UUID groupId) {
}
