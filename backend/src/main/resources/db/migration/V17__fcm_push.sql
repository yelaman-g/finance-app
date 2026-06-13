CREATE TABLE device_tokens (
    id          UUID PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token       VARCHAR(512) NOT NULL UNIQUE,
    platform    VARCHAR(16) NOT NULL DEFAULT 'ANDROID',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    version     BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_device_tokens_user ON device_tokens (user_id);

CREATE TABLE sent_notifications (
    id              UUID PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source_type     VARCHAR(16) NOT NULL,
    source_id       UUID NOT NULL,
    occurrence_date DATE NOT NULL,
    threshold_day   INTEGER NOT NULL,
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_sent UNIQUE (source_type, source_id, occurrence_date, threshold_day)
);
CREATE INDEX idx_sent_user ON sent_notifications (user_id);

ALTER TABLE events ADD COLUMN notify_days_before VARCHAR(60) NOT NULL DEFAULT '1,0';
