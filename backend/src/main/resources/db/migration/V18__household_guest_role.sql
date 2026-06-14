-- Extend household_role check constraint to include GUEST (view-only role)
ALTER TABLE users DROP CONSTRAINT chk_users_household_role;

ALTER TABLE users
    ADD CONSTRAINT chk_users_household_role
        CHECK (household_role IN ('OWNER', 'ADULT', 'CHILD', 'GUEST'));
