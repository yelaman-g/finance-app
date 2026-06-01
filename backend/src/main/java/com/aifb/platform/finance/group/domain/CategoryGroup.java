package com.aifb.platform.finance.group.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import com.aifb.platform.finance.category.domain.CategoryType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "category_groups")
public class CategoryGroup extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "household_id")
    private UUID householdId;

    @Column(nullable = false, length = 80)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private CategoryType type;

    @Column(length = 40)
    private String icon;

    @Column(length = 9)
    private String color;

    protected CategoryGroup() {
    }

    public CategoryGroup(UUID userId, String name, CategoryType type, String icon, String color) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.name = name;
        this.type = type;
        this.icon = icon;
        this.color = color;
    }

    public UUID getUserId() { return userId; }
    public UUID getHouseholdId() { return householdId; }
    public boolean isShared() { return householdId != null; }
    public String getName() { return name; }
    public CategoryType getType() { return type; }
    public String getIcon() { return icon; }
    public String getColor() { return color; }

    public void assignHousehold(UUID householdId) { this.householdId = householdId; }
    public void setName(String name) { this.name = name; }
    public void setIcon(String icon) { this.icon = icon; }
    public void setColor(String color) { this.color = color; }
}
