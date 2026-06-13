CREATE TABLE events (
    id              UUID PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    household_id    UUID REFERENCES households(id) ON DELETE CASCADE,
    title           VARCHAR(200) NOT NULL,
    description     VARCHAR(2000),
    start_date      DATE NOT NULL,
    start_time      TIME,
    all_day         BOOLEAN NOT NULL DEFAULT TRUE,
    type            VARCHAR(16) NOT NULL DEFAULT 'OTHER',
    recur_freq      VARCHAR(8) NOT NULL DEFAULT 'NONE',
    recur_interval  INTEGER NOT NULL DEFAULT 1,
    recur_until     DATE,
    ai_reminder_id  UUID REFERENCES ai_reminders(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    version         BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_events_user ON events (user_id);
CREATE INDEX idx_events_household ON events (household_id);
