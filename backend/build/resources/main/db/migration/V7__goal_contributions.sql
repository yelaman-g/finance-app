CREATE TABLE goal_contributions (
    id UUID PRIMARY KEY,
    goal_id UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
    amount NUMERIC(15,2) NOT NULL,
    note VARCHAR(255),
    contributed_on DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT chk_goal_contributions_amount_positive CHECK (amount > 0)
);

CREATE INDEX idx_goal_contributions_goal ON goal_contributions (goal_id, contributed_on DESC);
