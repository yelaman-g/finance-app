CREATE TABLE user_settings (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    currency VARCHAR(3) NOT NULL DEFAULT 'KZT',
    theme VARCHAR(10) NOT NULL DEFAULT 'light',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    version BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT uk_user_settings_user_id UNIQUE (user_id),
    CONSTRAINT chk_user_settings_currency CHECK (currency IN ('KZT', 'RUB', 'USD', 'AED', 'CNY'))
);
