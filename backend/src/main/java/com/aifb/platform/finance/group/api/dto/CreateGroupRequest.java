package com.aifb.platform.finance.group.api.dto;

import com.aifb.platform.finance.category.domain.CategoryType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CreateGroupRequest(
        @NotBlank @Size(max = 80) String name,
        @NotNull CategoryType type,
        @Size(max = 40) String icon,
        @Size(max = 9) String color,
        boolean shared) {
}
