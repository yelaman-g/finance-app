package com.aifb.platform.notification.service;

import com.aifb.platform.notification.domain.NotificationSource;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Кандидат на уведомление, вычисленный планировщиком.
 * ownerUserId — владелец источника; householdId != null → семейный (шлём всем членам).
 */
public record NotificationCandidate(
        NotificationSource sourceType,
        UUID sourceId,
        UUID ownerUserId,
        UUID householdId,
        LocalDate occurrenceDate,
        int thresholdDay,
        String title,
        String body) {}
