package com.aifb.platform.finance.categorization.api.dto;

import com.aifb.platform.finance.category.domain.CategoryType;
import jakarta.validation.constraints.NotNull;

public record SuggestRequest(String note, @NotNull CategoryType type) {
}
