ALTER TABLE categories   ADD COLUMN household_id UUID REFERENCES households(id) ON DELETE CASCADE;
ALTER TABLE transactions ADD COLUMN household_id UUID REFERENCES households(id) ON DELETE CASCADE;
ALTER TABLE goals        ADD COLUMN household_id UUID REFERENCES households(id) ON DELETE CASCADE;

CREATE INDEX idx_categories_household   ON categories   (household_id) WHERE household_id IS NOT NULL;
CREATE INDEX idx_transactions_household ON transactions (household_id) WHERE household_id IS NOT NULL;
CREATE INDEX idx_goals_household        ON goals        (household_id) WHERE household_id IS NOT NULL;
