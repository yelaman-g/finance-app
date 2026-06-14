package com.aifb.platform.chat.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.util.UUID;

/**
 * A chat message scoped to a single household.
 */
@Entity
@Table(name = "chat_messages")
public class ChatMessage extends BaseEntity {

    @Column(name = "household_id", nullable = false)
    private UUID householdId;

    @Column(name = "sender_id", nullable = false)
    private UUID senderId;

    @Column(nullable = false, length = 2000)
    private String text;

    protected ChatMessage() {
    }

    public ChatMessage(UUID householdId, UUID senderId, String text) {
        this.id = UUID.randomUUID();
        this.householdId = householdId;
        this.senderId = senderId;
        this.text = text;
    }

    public UUID getHouseholdId() { return householdId; }
    public UUID getSenderId() { return senderId; }
    public String getText() { return text; }
}
