package com.aifb.platform.social.wishlist.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "wishlist_items")
public class WishlistItem extends BaseEntity {

    @Column(name = "household_id", nullable = false)
    private UUID householdId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(length = 500)
    private String note;

    @Column(name = "reserved_by")
    private UUID reservedBy;

    protected WishlistItem() {
    }

    public WishlistItem(UUID householdId, UUID userId, String title, String note) {
        this.id = UUID.randomUUID();
        this.householdId = householdId;
        this.userId = userId;
        this.title = title;
        this.note = note;
    }

    public UUID getHouseholdId() { return householdId; }
    public UUID getUserId() { return userId; }
    public String getTitle() { return title; }
    public String getNote() { return note; }
    public UUID getReservedBy() { return reservedBy; }

    public void reserve(UUID by) {
        this.reservedBy = by;
    }

    public void clearReserve() {
        this.reservedBy = null;
    }
}
