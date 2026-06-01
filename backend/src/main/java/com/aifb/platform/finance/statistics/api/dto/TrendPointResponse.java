package com.aifb.platform.finance.statistics.api.dto;

import java.math.BigDecimal;

public record TrendPointResponse(String month, BigDecimal income, BigDecimal expense) {
}
