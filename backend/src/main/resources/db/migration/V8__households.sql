CREATE TABLE households (
    id UUID PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    owner_user_id UUID NOT NULL REFERENCES users(id),
    invite_code VARCHAR(12) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT uk_households_invite_code UNIQUE (invite_code)
);

ALTER TABLE users
    ADD COLUMN household_id UUID REFERENCES households(id) ON DELETE SET NULL,
    ADD COLUMN household_role VARCHAR(10);

ALTER TABLE users
    ADD CONSTRAINT chk_users_household_role
        CHECK (household_role IN ('OWNER', 'ADULT', 'CHILD'));

ALTER TABLE users
    ADD CONSTRAINT chk_users_household_consistency
        CHECK ((household_id IS NULL) = (household_role IS NULL));

CREATE INDEX idx_users_household ON users (household_id) WHERE household_id IS NOT NULL;
