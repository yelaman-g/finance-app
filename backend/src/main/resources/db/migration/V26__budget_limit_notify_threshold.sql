ALTER TABLE budget_limits
    ADD COLUMN notify_threshold_percent INTEGER NOT NULL DEFAULT 80
        CONSTRAINT chk_budget_limits_threshold_range CHECK (notify_threshold_percent BETWEEN 1 AND 100);
