CREATE TABLE transactions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id),
    type VARCHAR(10) NOT NULL,
    amount NUMERIC(15,2) NOT NULL,
    note VARCHAR(255),
    occurred_on DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT chk_transactions_type CHECK (type IN ('INCOME', 'EXPENSE')),
    CONSTRAINT chk_transactions_amount_positive CHECK (amount > 0)
);

CREATE INDEX idx_transactions_user_date ON transactions (user_id, occurred_on DESC);
CREATE INDEX idx_transactions_user_category ON transactions (user_id, category_id);
