package com.aifb.platform.finance.transaction.event;

import java.util.UUID;

/**
 * Опубликовано при создании любой операции типа EXPENSE (личной и семейной).
 * Слушается {@code BudgetAlertService} для проверки подхода к лимиту.
 * {@code householdId == null} → личная операция; иначе семейная.
 */
public record ExpenseRecordedEvent(UUID transactionId, UUID userId, UUID householdId, UUID categoryId) {}
