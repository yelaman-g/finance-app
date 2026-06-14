CREATE TABLE transaction_reactions (
    id             UUID PRIMARY KEY,
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emoji          VARCHAR(16) NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    version        BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT uk_reaction_tx_user UNIQUE (transaction_id, user_id)
);
CREATE INDEX idx_reaction_tx ON transaction_reactions (transaction_id);
