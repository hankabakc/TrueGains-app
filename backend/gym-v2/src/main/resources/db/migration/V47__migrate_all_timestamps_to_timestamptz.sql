-- V47: Migrate all TIMESTAMP columns to TIMESTAMPTZ for Hibernate 7 / Spring Boot 4 compatibility
-- This ensures all Instant fields in Java match the DB column type exactly.

-- 1. app_user table
ALTER TABLE app_user ALTER COLUMN registered_at TYPE TIMESTAMPTZ;
ALTER TABLE app_user ALTER COLUMN account_locked_until TYPE TIMESTAMPTZ;
ALTER TABLE app_user ALTER COLUMN last_login_at TYPE TIMESTAMPTZ;

-- 2. refresh_token table
ALTER TABLE refresh_token ALTER COLUMN expiry_date TYPE TIMESTAMPTZ;

-- 3. blacklisted_token table
ALTER TABLE blacklisted_token ALTER COLUMN expiry_date TYPE TIMESTAMPTZ;

-- 4. audit_log table
ALTER TABLE audit_log ALTER COLUMN created_at TYPE TIMESTAMPTZ;
