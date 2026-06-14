package com.aifb.platform.finance.budget.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "budget_limits")
public class BudgetLimit extends BaseEntity {

    public static final int DEFAULT_NOTIFY_THRESHOLD = 80;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "household_id")
    private UUID householdId;

    @Column(name = "category_id")
    private UUID categoryId;

    @Column(name = "group_id")
    private UUID groupId;

    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal amount;

    @Column(name = "notify_threshold_percent", nullable = false)
    private int notifyThresholdPercent = DEFAULT_NOTIFY_THRESHOLD;

    protected BudgetLimit() {
    }

    public BudgetLimit(UUID userId, UUID categoryId, UUID groupId, BigDecimal amount) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.categoryId = categoryId;
        this.groupId = groupId;
        this.amount = amount;
    }

    public UUID getUserId() { return userId; }
    public UUID getHouseholdId() { return householdId; }
    public boolean isShared() { return householdId != null; }
    public UUID getCategoryId() { return categoryId; }
    public UUID getGroupId() { return groupId; }
    public BigDecimal getAmount() { return amount; }
    public BudgetTargetType getTargetType() {
        return categoryId != null ? BudgetTargetType.CATEGORY : BudgetTargetType.GROUP;
    }

    public void assignHousehold(UUID householdId) { this.householdId = householdId; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
    public int getNotifyThresholdPercent() { return notifyThresholdPercent; }
    public void setNotifyThresholdPercent(int notifyThresholdPercent) { this.notifyThresholdPercent = notifyThresholdPercent; }
}
