package com.aifb.platform.social.capsule.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "time_capsules")
public class TimeCapsule extends BaseEntity {

    @Column(name = "household_id", nullable = false)
    private UUID householdId;

    @Column(name = "created_by", nullable = false)
    private UUID createdBy;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(nullable = false, length = 4000)
    private String message;

    @Column(name = "open_date", nullable = false)
    private LocalDate openDate;

    protected TimeCapsule() {}

    public TimeCapsule(UUID householdId, UUID createdBy, String title, String message, LocalDate openDate) {
        this.id = UUID.randomUUID();
        this.householdId = householdId;
        this.createdBy = createdBy;
        this.title = title;
        this.message = message;
        this.openDate = openDate;
    }

    public UUID getHouseholdId() { return householdId; }
    public UUID getCreatedBy()   { return createdBy; }
    public String getTitle()     { return title; }
    public String getMessage()   { return message; }
    public LocalDate getOpenDate() { return openDate; }
}
