CREATE TABLE ai_reminders (
    id                 UUID PRIMARY KEY,
    user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    household_id       UUID REFERENCES households(id) ON DELETE CASCADE,
    event_name         VARCHAR(200) NOT NULL,
    event_date         DATE NOT NULL,
    target_amount      NUMERIC(14,2),
    saved_amount       NUMERIC(14,2) NOT NULL DEFAULT 0,
    notify_days_before VARCHAR(60) NOT NULL DEFAULT '90,30,7,1',
    is_active          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    version            BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_ai_reminders_user ON ai_reminders (user_id);
CREATE INDEX idx_ai_reminders_household ON ai_reminders (household_id);
