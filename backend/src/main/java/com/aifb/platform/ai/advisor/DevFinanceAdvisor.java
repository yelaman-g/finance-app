package com.aifb.platform.ai.advisor;

import com.aifb.platform.finance.statistics.api.dto.CategoryBreakdownResponse;
import com.aifb.platform.finance.statistics.api.dto.SummaryResponse;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;

/**
 * Детерминированная реализация без обращения к сети. Используется в dev-режиме
 * (aifb.ai.dev-mode=true) для тестов и демо без ключа Anthropic. Ответы считаются
 * из реального финансового контекста.
 */
public class DevFinanceAdvisor implements FinanceAdvisor {

    @Override
    public ChatReply chat(FinanceContext ctx, List<ChatTurn> conversation) {
        SummaryResponse cur = ctx.currentMonth();
        String top = ctx.topExpenseCategories().isEmpty() ? "—"
                : ctx.topExpenseCategories().get(0).name();
        String c = ctx.currency().name();
        String text = String.format(
                "За текущий месяц доход %s %s, расход %s %s, баланс %s %s. "
                        + "Крупнейшая категория расходов — «%s». "
                        + "Совет: держите расход в этой категории под контролем.",
                cur.income(), c, cur.expense(), c, cur.net(), c, top);
        return new ChatReply(text, List.of("Показать расходы по категориям", "Установить лимит"));
    }

    @Override
    public BudgetAnalysis analyzeBudget(FinanceContext ctx) {
        SummaryResponse cur = ctx.currentMonth();
        SummaryResponse prev = ctx.previousMonth();
        String c = ctx.currency().name();
        String analysis = String.format(
                "Текущий месяц: расход %s %s (прошлый: %s %s), баланс %s %s.",
                cur.expense(), c, prev.expense(), c, cur.net(), c);
        List<String> tips = new ArrayList<>();
        if (cur.expense().compareTo(prev.expense()) > 0) {
            tips.add("Расходы выросли по сравнению с прошлым месяцем — проверьте крупные категории.");
        }
        if (cur.net().signum() < 0) {
            tips.add("Баланс отрицательный — расходы превышают доходы.");
        }
        if (tips.isEmpty()) {
            tips.add("Бюджет под контролем — так держать.");
        }
        return new BudgetAnalysis(analysis, tips);
    }

    @Override
    public List<Insight> insights(FinanceContext ctx) {
        List<Insight> out = new ArrayList<>();
        if (!ctx.topExpenseCategories().isEmpty()) {
            CategoryBreakdownResponse top = ctx.topExpenseCategories().get(0);
            out.add(new Insight(
                    "Крупнейшая категория расходов",
                    String.format("«%s» — %.0f%% всех расходов месяца.", top.name(), top.percentage()),
                    top.percentage() >= 40.0 ? "warning" : "recommendation",
                    top.total(), null));
        }
        int cmp = ctx.currentMonth().expense().compareTo(ctx.previousMonth().expense());
        if (cmp > 0) {
            out.add(new Insight("Рост расходов",
                    "Расходы выше, чем в прошлом месяце.", "prediction", null, null));
        } else if (cmp < 0) {
            out.add(new Insight("Снижение расходов",
                    "Вы тратите меньше, чем в прошлом месяце. Отлично!", "achievement", null, null));
        }
        if (ctx.currentMonth().net().signum() >= 0) {
            out.add(new Insight("Положительный баланс",
                    "Доходы покрывают расходы в этом месяце.", "achievement",
                    ctx.currentMonth().net(), null));
        }
        return out;
    }

    @Override
    public SavingsPlan savingsPlan(FinanceContext ctx, SavingsPlanInput input) {
        long days = ChronoUnit.DAYS.between(LocalDate.now(), input.eventDate());
        int months = (int) Math.max(1, Math.ceil(days / 30.0));
        BigDecimal saved = input.savedAmount() == null ? BigDecimal.ZERO : input.savedAmount();
        BigDecimal remaining = input.targetAmount().subtract(saved).max(BigDecimal.ZERO);
        BigDecimal monthly = remaining.divide(BigDecimal.valueOf(months), 2, RoundingMode.HALF_UP);
        boolean feasible = monthly.compareTo(ctx.currentMonth().net().max(BigDecimal.ZERO)) <= 0;
        String advice = String.format(
                "До события «%s» ~%d мес. Нужно откладывать %s %s в месяц. %s",
                input.eventName(), months, monthly, ctx.currency().name(),
                feasible ? "Это реально при текущем балансе." : "Это выше текущего месячного баланса — пересмотрите план.");
        return new SavingsPlan(monthly, months, feasible, advice);
    }
}
