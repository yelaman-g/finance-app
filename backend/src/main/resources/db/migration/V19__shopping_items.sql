CREATE TABLE shopping_items (
    id           UUID PRIMARY KEY,
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    title        VARCHAR(200) NOT NULL,
    checked      BOOLEAN NOT NULL DEFAULT FALSE,
    created_by   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    version      BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_shopping_items_household ON shopping_items (household_id);
