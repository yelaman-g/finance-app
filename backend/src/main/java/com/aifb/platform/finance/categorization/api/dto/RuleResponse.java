package com.aifb.platform.finance.categorization.api.dto;

import java.util.UUID;

public record RuleResponse(UUID id, String keyword, UUID categoryId, String categoryName) {
}
