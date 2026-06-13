CREATE TABLE goals (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(120) NOT NULL,
    target_amount NUMERIC(15,2) NOT NULL,
    deadline DATE,
    status VARCHAR(12) NOT NULL DEFAULT 'ACTIVE',
    icon VARCHAR(40),
    color VARCHAR(9),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT chk_goals_target_positive CHECK (target_amount > 0),
    CONSTRAINT chk_goals_status CHECK (status IN ('ACTIVE', 'COMPLETED', 'ARCHIVED'))
);

CREATE INDEX idx_goals_user ON goals (user_id);
