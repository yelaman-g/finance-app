package com.aifb.platform.finance.transaction.event;

import java.math.BigDecimal;
import java.util.UUID;

/** Опубликовано при создании семейного расхода (shared EXPENSE). Слушается модулем notification. */
public record SharedExpenseCreatedEvent(UUID householdId, UUID authorUserId,
                                        UUID transactionId, BigDecimal amount, String note) {}
