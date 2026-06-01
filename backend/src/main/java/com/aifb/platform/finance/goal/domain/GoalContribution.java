package com.aifb.platform.finance.goal.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "goal_contributions")
public class GoalContribution extends BaseEntity {

    @Column(name = "goal_id", nullable = false)
    private UUID goalId;

    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal amount;

    @Column(length = 255)
    private String note;

    @Column(name = "contributed_on", nullable = false)
    private LocalDate contributedOn;

    protected GoalContribution() {
    }

    public GoalContribution(UUID goalId, BigDecimal amount, String note, LocalDate contributedOn) {
        this.id = UUID.randomUUID();
        this.goalId = goalId;
        this.amount = amount;
        this.note = note;
        this.contributedOn = contributedOn;
    }

    public UUID getGoalId() { return goalId; }
    public BigDecimal getAmount() { return amount; }
    public String getNote() { return note; }
    public LocalDate getContributedOn() { return contributedOn; }
}
