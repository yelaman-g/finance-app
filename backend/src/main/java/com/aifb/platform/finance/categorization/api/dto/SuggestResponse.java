package com.aifb.platform.finance.categorization.api.dto;

import java.util.UUID;

public record SuggestResponse(UUID categoryId, String categoryName) {
}
