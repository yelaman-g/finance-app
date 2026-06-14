package com.aifb.platform.social.reaction.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "transaction_reactions")
public class TransactionReaction extends BaseEntity {

    @Column(name = "transaction_id", nullable = false, updatable = false)
    private UUID transactionId;

    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    @Column(nullable = false, length = 16)
    private String emoji;

    protected TransactionReaction() {
    }

    public TransactionReaction(UUID transactionId, UUID userId, String emoji) {
        this.id = UUID.randomUUID();
        this.transactionId = transactionId;
        this.userId = userId;
        this.emoji = emoji;
    }

    public UUID getTransactionId() { return transactionId; }
    public UUID getUserId() { return userId; }
    public String getEmoji() { return emoji; }
    public void setEmoji(String emoji) { this.emoji = emoji; }
}
