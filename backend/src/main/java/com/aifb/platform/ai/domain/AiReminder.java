package com.aifb.platform.ai.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Entity
@Table(name = "ai_reminders")
public class AiReminder extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "household_id")
    private UUID householdId;

    @Column(name = "event_name", nullable = false, length = 200)
    private String eventName;

    @Column(name = "event_date", nullable = false)
    private LocalDate eventDate;

    @Column(name = "target_amount", precision = 14, scale = 2)
    private BigDecimal targetAmount;

    @Column(name = "saved_amount", nullable = false, precision = 14, scale = 2)
    private BigDecimal savedAmount = BigDecimal.ZERO;

    @Column(name = "notify_days_before", nullable = false, length = 60)
    private String notifyDaysBefore = "90,30,7,1";

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    protected AiReminder() {
    }

    public AiReminder(UUID userId, String eventName, LocalDate eventDate,
                      BigDecimal targetAmount, BigDecimal savedAmount, List<Integer> notifyDaysBefore) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.eventName = eventName;
        this.eventDate = eventDate;
        this.targetAmount = targetAmount;
        this.savedAmount = savedAmount == null ? BigDecimal.ZERO : savedAmount;
        if (notifyDaysBefore != null && !notifyDaysBefore.isEmpty()) {
            this.notifyDaysBefore = notifyDaysBefore.stream().map(String::valueOf)
                    .collect(Collectors.joining(","));
        }
    }

    public UUID getUserId() { return userId; }
    public UUID getHouseholdId() { return householdId; }
    public boolean isShared() { return householdId != null; }
    public void assignHousehold(UUID householdId) { this.householdId = householdId; }
    public String getEventName() { return eventName; }
    public LocalDate getEventDate() { return eventDate; }
    public BigDecimal getTargetAmount() { return targetAmount; }
    public BigDecimal getSavedAmount() { return savedAmount; }
    public boolean isActive() { return active; }

    public List<Integer> getNotifyDaysBefore() {
        if (notifyDaysBefore == null || notifyDaysBefore.isBlank()) {
            return List.of();
        }
        return Arrays.stream(notifyDaysBefore.split(","))
                .map(String::trim).filter(s -> !s.isEmpty())
                .map(Integer::valueOf).toList();
    }
}
