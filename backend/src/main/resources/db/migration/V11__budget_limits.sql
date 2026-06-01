CREATE TABLE budget_limits (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    household_id UUID REFERENCES households(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    group_id UUID REFERENCES category_groups(id) ON DELETE CASCADE,
    amount NUMERIC(15,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT chk_budget_limits_amount_positive CHECK (amount > 0),
    CONSTRAINT chk_budget_limits_one_target CHECK ((category_id IS NULL) <> (group_id IS NULL))
);

CREATE UNIQUE INDEX uk_budget_limits_category ON budget_limits (category_id) WHERE category_id IS NOT NULL;
CREATE UNIQUE INDEX uk_budget_limits_group ON budget_limits (group_id) WHERE group_id IS NOT NULL;
CREATE INDEX idx_budget_limits_user ON budget_limits (user_id) WHERE household_id IS NULL;
CREATE INDEX idx_budget_limits_household ON budget_limits (household_id) WHERE household_id IS NOT NULL;
