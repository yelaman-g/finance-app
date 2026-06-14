package com.aifb.platform.finance.budget.domain;

import java.math.BigDecimal;

public enum BudgetStatus {
    OK,
    WARNING,
    EXCEEDED;

    /** spent/limit: <thresholdPercent% OK, ≥thresholdPercent% WARNING, >100% EXCEEDED. limit>0 гарантирован. */
    public static BudgetStatus of(BigDecimal spent, BigDecimal limit, int thresholdPercent) {
        double ratio = spent.doubleValue() / limit.doubleValue();
        if (ratio > 1.0) {
            return EXCEEDED;
        }
        if (ratio * 100 >= thresholdPercent) {
            return WARNING;
        }
        return OK;
    }
}
