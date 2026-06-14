CREATE TABLE feed_moments (
    id           UUID PRIMARY KEY,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    author_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    text         VARCHAR(2000) NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    version      BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_feed_household ON feed_moments (household_id);

CREATE TABLE feed_likes (
    id         UUID PRIMARY KEY,
    moment_id  UUID NOT NULL REFERENCES feed_moments(id) ON DELETE CASCADE,
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uk_feed_like UNIQUE (moment_id, user_id)
);
CREATE INDEX idx_feed_likes_moment ON feed_likes (moment_id);
