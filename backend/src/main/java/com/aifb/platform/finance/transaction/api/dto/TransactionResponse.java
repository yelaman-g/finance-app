package com.aifb.platform.finance.transaction.api.dto;

import com.aifb.platform.finance.budget.api.dto.BudgetWarning;
import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.transaction.domain.Transaction;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public record TransactionResponse(
        UUID id, UUID categoryId, String categoryName, String categoryColor,
        String categoryIcon, String type, BigDecimal amount, String note,
        LocalDate occurredOn, Instant createdAt, boolean shared, UUID authorId,
        List<BudgetWarning> budgetWarnings) {

    public static TransactionResponse from(Transaction t, Category category) {
        return from(t, category, null);
    }

    public static TransactionResponse from(Transaction t, Category category,
                                           List<BudgetWarning> budgetWarnings) {
        return new TransactionResponse(
                t.getId(), t.getCategoryId(),
                category == null ? null : category.getName(),
                category == null ? null : category.getColor(),
                category == null ? null : category.getIcon(),
                t.getType().name(), t.getAmount(), t.getNote(),
                t.getOccurredOn(), t.getCreatedAt(), t.isShared(), t.getUserId(),
                budgetWarnings == null || budgetWarnings.isEmpty() ? null : budgetWarnings);
    }
}
