package com.aifb.platform.social.poll.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.UUID;

@Entity
@Table(name = "poll_options")
public class PollOption {

    @Id
    @JdbcTypeCode(SqlTypes.UUID)
    @Column(columnDefinition = "uuid", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "poll_id", nullable = false)
    private UUID pollId;

    @Column(nullable = false, length = 200)
    private String text;

    @Column(nullable = false)
    private int position;

    protected PollOption() {}

    public PollOption(UUID pollId, String text, int position) {
        this.id = UUID.randomUUID();
        this.pollId = pollId;
        this.text = text;
        this.position = position;
    }

    public UUID getId() { return id; }
    public UUID getPollId() { return pollId; }
    public String getText() { return text; }
    public int getPosition() { return position; }
}
