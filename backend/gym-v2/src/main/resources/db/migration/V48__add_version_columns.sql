-- V48: Missing Version Columns
-- This migration adds the version columns required by Hibernate @Version annotation.
-- These were moved from V47 to avoid checksum mismatches.

-- 1. app_user table
ALTER TABLE app_user ADD COLUMN IF NOT EXISTS version BIGINT DEFAULT 0;

-- 2. blacklisted_token table
ALTER TABLE blacklisted_token ADD COLUMN IF NOT EXISTS version BIGINT DEFAULT 0;

-- 3. diet_program table
ALTER TABLE diet_program ADD COLUMN IF NOT EXISTS version BIGINT DEFAULT 0;

-- 4. training_blocks table
ALTER TABLE training_blocks ADD COLUMN IF NOT EXISTS version BIGINT DEFAULT 0;

-- 5. pairing_request table
ALTER TABLE pairing_request ADD COLUMN IF NOT EXISTS version BIGINT DEFAULT 0;
