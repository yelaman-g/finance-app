package com.aifb.platform.finance.category.api.dto;

import com.aifb.platform.finance.category.domain.CategoryType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CreateCategoryRequest(
        @NotBlank @Size(max = 80) String name,
        @NotNull CategoryType type,
        @Size(max = 40) String icon,
        @Size(max = 9) String color) {
}
