-- Aligns refresh_tokens.token_hash with the JPA entity (String + length=64 → VARCHAR(64)).
-- Length is guaranteed by the existing CHECK constraint chk_refresh_tokens_hash_hex,
-- so the CHAR → VARCHAR change is safe and lossless.
ALTER TABLE refresh_tokens
    ALTER COLUMN token_hash TYPE VARCHAR(64);
