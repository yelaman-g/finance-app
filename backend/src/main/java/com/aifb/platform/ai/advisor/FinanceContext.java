package com.aifb.platform.ai.advisor;

import com.aifb.platform.common.domain.Currency;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.finance.statistics.api.dto.CategoryBreakdownResponse;
import com.aifb.platform.finance.statistics.api.dto.SummaryResponse;
import com.aifb.platform.finance.statistics.api.dto.TrendPointResponse;

import java.util.List;

public record FinanceContext(
        Currency currency,
        Scope scope,
        SummaryResponse currentMonth,
        SummaryResponse previousMonth,
        List<CategoryBreakdownResponse> topExpenseCategories,
        List<TrendPointResponse> trend) {
}
