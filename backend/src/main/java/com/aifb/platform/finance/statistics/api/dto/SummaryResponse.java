package com.aifb.platform.finance.statistics.api.dto;

import java.math.BigDecimal;

public record SummaryResponse(BigDecimal income, BigDecimal expense, BigDecimal net) {
}
