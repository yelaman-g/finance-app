package com.aifb.platform.finance.statistics.api.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record MemberBreakdownResponse(
        UUID userId, String fullName, BigDecimal income, BigDecimal expense) {
}
