package com.aifb.platform.ai.service;

import com.aifb.platform.ai.advisor.FinanceAdvisor;
import com.aifb.platform.ai.advisor.FinanceContext;
import com.aifb.platform.ai.advisor.FinanceContextBuilder;
import com.aifb.platform.ai.api.dto.*;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.event.service.EventService;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
public class AiService {

    private final FinanceContextBuilder contextBuilder;
    private final FinanceAdvisor advisor;
    private final EventService eventService;

    public AiService(FinanceContextBuilder contextBuilder, FinanceAdvisor advisor,
                     EventService eventService) {
        this.contextBuilder = contextBuilder;
        this.advisor = advisor;
        this.eventService = eventService;
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

    public DigestResponse digest(UUID userId) {
        FinanceContext ctx = contextBuilder.build(userId, null);

        FinanceAdvisor.BudgetAnalysis budget = advisor.analyzeBudget(ctx);
        String narrative = budget.analysis();
        String tipOfDay = budget.tips().isEmpty() ? "" : budget.tips().get(0);

        List<String> highlights = advisor.insights(ctx).stream()
                .map(FinanceAdvisor.Insight::title)
                .toList();

        LocalDate today = LocalDate.now();
        List<DigestResponse.DigestEvent> upcomingEvents = eventService
                .list(userId, today, today.plusDays(7), Scope.PERSONAL)
                .stream()
                .limit(5)
                .map(e -> new DigestResponse.DigestEvent(e.title(), e.date()))
                .toList();

        return new DigestResponse(tipOfDay, narrative, highlights, upcomingEvents);
    }
}
