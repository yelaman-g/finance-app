package com.aifb.platform.ai.api.dto;
import java.math.BigDecimal;
public record SavingsPlanResponse(BigDecimal monthlyAmount, int monthsRemaining,
                                  boolean feasible, String advice) {}
