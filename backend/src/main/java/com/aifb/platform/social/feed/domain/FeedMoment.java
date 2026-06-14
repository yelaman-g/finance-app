package com.aifb.platform.social.feed.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "feed_moments")
public class FeedMoment extends BaseEntity {

    @Column(name = "household_id", nullable = false)
    private UUID householdId;

    @Column(name = "author_id", nullable = false)
    private UUID authorId;

    @Column(nullable = false, length = 2000)
    private String text;

    protected FeedMoment() {}

    public FeedMoment(UUID householdId, UUID authorId, String text) {
        this.id = UUID.randomUUID();
        this.householdId = householdId;
        this.authorId = authorId;
        this.text = text;
    }

    public UUID getHouseholdId() { return householdId; }
    public UUID getAuthorId() { return authorId; }
    public String getText() { return text; }
}
