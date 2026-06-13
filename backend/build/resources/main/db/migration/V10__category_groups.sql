CREATE TABLE category_groups (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    household_id UUID REFERENCES households(id) ON DELETE CASCADE,
    name VARCHAR(80) NOT NULL,
    type VARCHAR(10) NOT NULL,
    icon VARCHAR(40),
    color VARCHAR(9),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT chk_category_groups_type CHECK (type IN ('INCOME', 'EXPENSE'))
);

CREATE INDEX idx_category_groups_user ON category_groups (user_id) WHERE household_id IS NULL;
CREATE INDEX idx_category_groups_household ON category_groups (household_id) WHERE household_id IS NOT NULL;

ALTER TABLE categories ADD COLUMN group_id UUID REFERENCES category_groups(id) ON DELETE SET NULL;
