package com.aifb.platform.social.poll.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "polls")
public class Poll extends BaseEntity {

    @Column(name = "household_id", nullable = false)
    private UUID householdId;

    @Column(name = "created_by", nullable = false)
    private UUID createdBy;

    @Column(nullable = false, length = 300)
    private String question;

    @Column(nullable = false)
    private boolean closed;

    protected Poll() {}

    public Poll(UUID householdId, UUID createdBy, String question) {
        this.id = UUID.randomUUID();
        this.householdId = householdId;
        this.createdBy = createdBy;
        this.question = question;
        this.closed = false;
    }

    public UUID getHouseholdId() { return householdId; }
    public UUID getCreatedBy() { return createdBy; }
    public String getQuestion() { return question; }
    public boolean isClosed() { return closed; }

    public void close() {
        this.closed = true;
    }
}
