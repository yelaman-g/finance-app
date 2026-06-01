package com.aifb.platform.finance.statistics.api.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record CategoryBreakdownResponse(
        UUID categoryId,
        String name,
        String color,
        BigDecimal total,
        double percentage) {
}
