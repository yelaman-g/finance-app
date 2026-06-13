package com.aifb.platform.notification.repository;

import com.aifb.platform.notification.domain.NotificationSource;
import com.aifb.platform.notification.domain.SentNotification;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.UUID;

public interface SentNotificationRepository extends JpaRepository<SentNotification, UUID> {
    boolean existsBySourceTypeAndSourceIdAndOccurrenceDateAndThresholdDay(
            NotificationSource sourceType, UUID sourceId, LocalDate occurrenceDate, int thresholdDay);
}
