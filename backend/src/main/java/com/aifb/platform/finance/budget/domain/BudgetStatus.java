package com.aifb.platform.finance.budget.domain;

import java.math.BigDecimal;

public enum BudgetStatus {
    OK,
    WARNING,
    EXCEEDED;

    /** spent/limit: <80% OK, 80–100% WARNING, >100% EXCEEDED. limit>0 гарантирован. */
    public static BudgetStatus of(BigDecimal spent, BigDecimal limit) {
        double ratio = spent.doubleValue() / limit.doubleValue();
        if (ratio > 1.0) {
            return EXCEEDED;
        }
        if (ratio >= 0.8) {
            return WARNING;
        }
        return OK;
    }
}
