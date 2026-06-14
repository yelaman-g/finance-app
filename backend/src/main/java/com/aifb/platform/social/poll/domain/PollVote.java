package com.aifb.platform.social.poll.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "poll_votes")
public class PollVote {

    @Id
    @JdbcTypeCode(SqlTypes.UUID)
    @Column(columnDefinition = "uuid", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "poll_id", nullable = false)
    private UUID pollId;

    @Column(name = "option_id", nullable = false)
    private UUID optionId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected PollVote() {}

    public PollVote(UUID pollId, UUID optionId, UUID userId) {
        this.id = UUID.randomUUID();
        this.pollId = pollId;
        this.optionId = optionId;
        this.userId = userId;
        this.createdAt = Instant.now();
    }

    public UUID getId() { return id; }
    public UUID getPollId() { return pollId; }
    public UUID getOptionId() { return optionId; }
    public UUID getUserId() { return userId; }
    public Instant getCreatedAt() { return createdAt; }
}
