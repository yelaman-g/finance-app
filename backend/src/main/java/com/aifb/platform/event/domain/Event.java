package com.aifb.platform.event.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

@Entity
@Table(name = "events")
public class Event extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "household_id")
    private UUID householdId;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(length = 2000)
    private String description;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "start_time")
    private LocalTime startTime;

    @Column(name = "all_day", nullable = false)
    private boolean allDay = true;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private EventType type = EventType.OTHER;

    @Enumerated(EnumType.STRING)
    @Column(name = "recur_freq", nullable = false, length = 8)
    private RecurFreq recurFreq = RecurFreq.NONE;

    @Column(name = "recur_interval", nullable = false)
    private int recurInterval = 1;

    @Column(name = "recur_until")
    private LocalDate recurUntil;

    @Column(name = "ai_reminder_id")
    private UUID aiReminderId;

    protected Event() {
    }

    public Event(UUID userId, String title, String description, LocalDate startDate,
                 LocalTime startTime, boolean allDay, EventType type,
                 RecurFreq recurFreq, int recurInterval, LocalDate recurUntil) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.title = title;
        this.description = description;
        this.startDate = startDate;
        this.startTime = startTime;
        this.allDay = allDay;
        this.type = type == null ? EventType.OTHER : type;
        this.recurFreq = recurFreq == null ? RecurFreq.NONE : recurFreq;
        this.recurInterval = recurInterval < 1 ? 1 : recurInterval;
        this.recurUntil = recurUntil;
    }

    public UUID getUserId() { return userId; }
    public UUID getHouseholdId() { return householdId; }
    public boolean isShared() { return householdId != null; }
    public void assignHousehold(UUID householdId) { this.householdId = householdId; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public LocalDate getStartDate() { return startDate; }
    public LocalTime getStartTime() { return startTime; }
    public boolean isAllDay() { return allDay; }
    public EventType getType() { return type; }
    public RecurFreq getRecurFreq() { return recurFreq; }
    public int getRecurInterval() { return recurInterval; }
    public LocalDate getRecurUntil() { return recurUntil; }
    public UUID getAiReminderId() { return aiReminderId; }
    public void setAiReminderId(UUID id) { this.aiReminderId = id; }

    public void edit(String title, String description, LocalDate startDate, LocalTime startTime,
                     boolean allDay, EventType type, RecurFreq recurFreq, int recurInterval, LocalDate recurUntil) {
        this.title = title;
        this.description = description;
        this.startDate = startDate;
        this.startTime = startTime;
        this.allDay = allDay;
        this.type = type == null ? EventType.OTHER : type;
        this.recurFreq = recurFreq == null ? RecurFreq.NONE : recurFreq;
        this.recurInterval = recurInterval < 1 ? 1 : recurInterval;
        this.recurUntil = recurUntil;
    }
}
