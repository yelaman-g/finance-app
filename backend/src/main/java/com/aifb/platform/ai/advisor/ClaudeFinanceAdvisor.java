package com.aifb.platform.ai.advisor;

import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.common.exception.ErrorCode;
import com.anthropic.client.AnthropicClient;
import com.anthropic.client.okhttp.AnthropicOkHttpClient;
import com.anthropic.models.messages.Message;
import com.anthropic.models.messages.MessageCreateParams;

import java.util.List;

/**
 * Реальная реализация на Anthropic Java SDK. Активна при aifb.ai.dev-mode=false.
 * Системный промпт ограничивает модель темой финансов (ТЗ §6.2, §6.5).
 * Инсайты/план — детерминированная арифметика (DevFinanceAdvisor): надёжно;
 * чат/анализ — реальный Claude.
 */
public class ClaudeFinanceAdvisor implements FinanceAdvisor {

    private static final String SYSTEM_PROMPT = """
            Ты финансовый помощник семейного приложения Family App. Помогаешь семье вести бюджет,
            планировать накопления и напоминать о важных событиях. Отвечай ТОЛЬКО на вопросы о
            финансах, бюджете и планировании. Если спрашивают о другом — вежливо объясни, что ты
            специализируешься только на финансах семьи. Используй данные о доходах и расходах из
            контекста запроса. Давай конкретные цифры и практические советы. Отвечай по-русски.
            """;

    private final AnthropicClient client;
    private final String model;
    private final long maxTokens;
    private final DevFinanceAdvisor fallback = new DevFinanceAdvisor();

    public ClaudeFinanceAdvisor(String apiKey, String model, long maxTokens) {
        this.client = AnthropicOkHttpClient.builder().apiKey(apiKey).build();
        this.model = model;
        this.maxTokens = maxTokens;
    }

    private String complete(String userText) {
        try {
            MessageCreateParams params = MessageCreateParams.builder()
                    .model(model)
                    .maxTokens(maxTokens)
                    .system(SYSTEM_PROMPT)
                    .addUserMessage(userText)
                    .build();
            Message resp = client.messages().create(params);
            StringBuilder sb = new StringBuilder();
            resp.content().stream()
                    .flatMap(b -> b.text().stream())
                    .forEach(t -> sb.append(t.text()));
            return sb.toString();
        } catch (Exception e) {
            throw new DomainException(ErrorCode.AI_UNAVAILABLE, "AI service unavailable");
        }
    }

    @Override
    public ChatReply chat(FinanceContext ctx, List<ChatTurn> conversation) {
        String last = conversation.isEmpty() ? "" : conversation.get(conversation.size() - 1).content();
        String prompt = serialize(ctx) + "\n\nВопрос пользователя: " + last;
        return new ChatReply(complete(prompt), List.of());
    }

    @Override
    public BudgetAnalysis analyzeBudget(FinanceContext ctx) {
        String text = complete(serialize(ctx) + "\n\nДай краткий анализ бюджета за месяц и 2-3 совета.");
        return new BudgetAnalysis(text, List.of());
    }

    @Override
    public List<Insight> insights(FinanceContext ctx) {
        return fallback.insights(ctx);
    }

    @Override
    public SavingsPlan savingsPlan(FinanceContext ctx, SavingsPlanInput input) {
        return fallback.savingsPlan(ctx, input);
    }

    private String serialize(FinanceContext ctx) {
        String c = ctx.currency().name();
        return String.format(
                "Контекст (валюта %s, режим %s): текущий месяц доход=%s расход=%s баланс=%s; "
                        + "прошлый месяц расход=%s; топ-категории расходов=%s.",
                c, ctx.scope(), ctx.currentMonth().income(), ctx.currentMonth().expense(),
                ctx.currentMonth().net(), ctx.previousMonth().expense(),
                ctx.topExpenseCategories());
    }
}
