package com.aifb.platform.notification.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "sent_notifications")
public class SentNotification {

    @Id
    @JdbcTypeCode(SqlTypes.UUID)
    @Column(columnDefinition = "uuid", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "source_type", nullable = false, length = 16)
    private NotificationSource sourceType;

    @Column(name = "source_id", nullable = false)
    private UUID sourceId;

    @Column(name = "occurrence_date", nullable = false)
    private LocalDate occurrenceDate;

    @Column(name = "threshold_day", nullable = false)
    private int thresholdDay;

    @Column(name = "sent_at", nullable = false)
    private Instant sentAt = Instant.now();

    protected SentNotification() {}

    public SentNotification(UUID userId, NotificationSource sourceType, UUID sourceId,
                            LocalDate occurrenceDate, int thresholdDay) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.sourceType = sourceType;
        this.sourceId = sourceId;
        this.occurrenceDate = occurrenceDate;
        this.thresholdDay = thresholdDay;
        this.sentAt = Instant.now();
    }

    public UUID getId() { return id; }
}
