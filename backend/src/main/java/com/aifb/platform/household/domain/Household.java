package com.aifb.platform.household.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "households")
public class Household extends BaseEntity {

    @Column(nullable = false, length = 120)
    private String name;

    @Column(name = "owner_user_id", nullable = false)
    private UUID ownerUserId;

    @Column(name = "invite_code", nullable = false, length = 12)
    private String inviteCode;

    protected Household() {
    }

    public Household(String name, UUID ownerUserId, String inviteCode) {
        this.id = UUID.randomUUID();
        this.name = name;
        this.ownerUserId = ownerUserId;
        this.inviteCode = inviteCode;
    }

    public String getName() { return name; }
    public UUID getOwnerUserId() { return ownerUserId; }
    public String getInviteCode() { return inviteCode; }

    public void setName(String name) { this.name = name; }
    public void setInviteCode(String inviteCode) { this.inviteCode = inviteCode; }
}
