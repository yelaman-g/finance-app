-- Google-аккаунты не имеют локального пароля.
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;

-- Стабильный идентификатор Google-личности (sub из ID-token).
ALTER TABLE users ADD COLUMN google_subject VARCHAR(255);
ALTER TABLE users ADD CONSTRAINT uq_users_google_subject UNIQUE (google_subject);
