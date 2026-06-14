CREATE TABLE polls (
    id           UUID PRIMARY KEY,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    created_by   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question     VARCHAR(300) NOT NULL,
    closed       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    version      BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_polls_household ON polls (household_id);

CREATE TABLE poll_options (
    id        UUID PRIMARY KEY,
    poll_id   UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    text      VARCHAR(200) NOT NULL,
    position  INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_poll_options_poll ON poll_options (poll_id);

CREATE TABLE poll_votes (
    id        UUID PRIMARY KEY,
    poll_id   UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES poll_options(id) ON DELETE CASCADE,
    user_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uk_vote_poll_user UNIQUE (poll_id, user_id)
);
CREATE INDEX idx_poll_votes_poll ON poll_votes (poll_id);
