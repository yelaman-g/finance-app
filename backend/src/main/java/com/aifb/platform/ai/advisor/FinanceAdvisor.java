package com.aifb.platform.ai.advisor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface FinanceAdvisor {

    ChatReply chat(FinanceContext ctx, List<ChatTurn> conversation);
    BudgetAnalysis analyzeBudget(FinanceContext ctx);
    List<Insight> insights(FinanceContext ctx);
    SavingsPlan savingsPlan(FinanceContext ctx, SavingsPlanInput input);

    record ChatTurn(String role, String content) {}
    record ChatReply(String content, List<String> suggestedActions) {}
    record Insight(String title, String description, String type,
                   BigDecimal impactValue, String impactLabel) {}
    record BudgetAnalysis(String analysis, List<String> tips) {}
    record SavingsPlanInput(String eventName, LocalDate eventDate,
                            BigDecimal targetAmount, BigDecimal savedAmount) {}
    record SavingsPlan(BigDecimal monthlyAmount, int monthsRemaining,
                       boolean feasible, String advice) {}
}
