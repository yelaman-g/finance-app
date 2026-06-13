package com.aifb.platform.ai.service;

import com.aifb.platform.ai.advisor.FinanceAdvisor;
import com.aifb.platform.ai.advisor.FinanceContext;
import com.aifb.platform.ai.advisor.FinanceContextBuilder;
import com.aifb.platform.ai.api.dto.*;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class AiService {

    private final FinanceContextBuilder contextBuilder;
    private final FinanceAdvisor advisor;

    public AiService(FinanceContextBuilder contextBuilder, FinanceAdvisor advisor) {
        this.contextBuilder = contextBuilder;
        this.advisor = advisor;
    }

    public AiMessageResponse chat(UUID userId, ChatRequest request) {
        FinanceContext ctx = contextBuilder.build(userId, null);
        List<FinanceAdvisor.ChatTurn> turns = request.messages().stream()
                .map(m -> new FinanceAdvisor.ChatTurn(m.role(), m.content())).toList();
        FinanceAdvisor.ChatReply reply = advisor.chat(ctx, turns);
        return new AiMessageResponse("ai", reply.content(), reply.suggestedActions());
    }

    public BudgetAnalysisResponse analyzeBudget(UUID userId, AnalyzeBudgetRequest request) {
        FinanceContext ctx = contextBuilder.build(userId, request == null ? null : request.scope());
        FinanceAdvisor.BudgetAnalysis a = advisor.analyzeBudget(ctx);
        return new BudgetAnalysisResponse(a.analysis(), a.tips());
    }

    public List<InsightResponse> insights(UUID userId) {
        FinanceContext ctx = contextBuilder.build(userId, null);
        List<FinanceAdvisor.Insight> list = advisor.insights(ctx);
        return java.util.stream.IntStream.range(0, list.size())
                .mapToObj(i -> {
                    FinanceAdvisor.Insight x = list.get(i);
                    return new InsightResponse(String.valueOf(i), x.title(), x.description(),
                            x.type(), x.impactValue(), x.impactLabel());
                }).toList();
    }

    public SavingsPlanResponse savingsPlan(UUID userId, SavingsPlanRequest request) {
        FinanceContext ctx = contextBuilder.build(userId, null);
        FinanceAdvisor.SavingsPlan p = advisor.savingsPlan(ctx,
                new FinanceAdvisor.SavingsPlanInput(request.eventName(), request.eventDate(),
                        request.targetAmount(), request.savedAmount()));
        return new SavingsPlanResponse(p.monthlyAmount(), p.monthsRemaining(), p.feasible(), p.advice());
    }
}
