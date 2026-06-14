package com.aifb.platform.shopping.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "shopping_items")
public class ShoppingItem extends BaseEntity {

    @Column(name = "household_id", nullable = false)
    private UUID householdId;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(nullable = false)
    private boolean checked = false;

    @Column(name = "created_by", nullable = false)
    private UUID createdBy;

    protected ShoppingItem() {
    }

    public ShoppingItem(UUID householdId, String title, UUID createdBy) {
        this.id = UUID.randomUUID();
        this.householdId = householdId;
        this.title = title;
        this.createdBy = createdBy;
        this.checked = false;
    }

    public UUID getHouseholdId() { return householdId; }
    public String getTitle() { return title; }
    public boolean isChecked() { return checked; }
    public UUID getCreatedBy() { return createdBy; }

    public void toggle() {
        this.checked = !this.checked;
    }
}
