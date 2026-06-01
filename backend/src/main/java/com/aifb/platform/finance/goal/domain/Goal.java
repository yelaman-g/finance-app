package com.aifb.platform.finance.goal.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "goals")
public class Goal extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(name = "target_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal targetAmount;

    @Column
    private LocalDate deadline;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 12)
    private GoalStatus status;

    @Column(length = 40)
    private String icon;

    @Column(length = 9)
    private String color;

    @Column(name = "household_id")
    private UUID householdId;

    protected Goal() {
    }

    public Goal(UUID userId, String name, BigDecimal targetAmount,
                LocalDate deadline, String icon, String color) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.name = name;
        this.targetAmount = targetAmount;
        this.deadline = deadline;
        this.icon = icon;
        this.color = color;
        this.status = GoalStatus.ACTIVE;
    }

    public UUID getUserId() { return userId; }
    public String getName() { return name; }
    public BigDecimal getTargetAmount() { return targetAmount; }
    public LocalDate getDeadline() { return deadline; }
    public GoalStatus getStatus() { return status; }
    public String getIcon() { return icon; }
    public String getColor() { return color; }
    public UUID getHouseholdId() { return householdId; }
    public boolean isShared() { return householdId != null; }
    public void assignHousehold(UUID householdId) { this.householdId = householdId; }

    public void setName(String name) { this.name = name; }
    public void setTargetAmount(BigDecimal targetAmount) { this.targetAmount = targetAmount; }
    public void setDeadline(LocalDate deadline) { this.deadline = deadline; }
    public void setIcon(String icon) { this.icon = icon; }
    public void setColor(String color) { this.color = color; }
    public void setStatus(GoalStatus status) { this.status = status; }

    public void recomputeStatus(BigDecimal savedAmount) {
        if (status == GoalStatus.ARCHIVED) {
            return;
        }
        status = savedAmount.compareTo(targetAmount) >= 0
                ? GoalStatus.COMPLETED
                : GoalStatus.ACTIVE;
    }
}
