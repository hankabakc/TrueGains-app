-- V94: Update blacklisted_token columns for JWT ID (jti) usage
DROP INDEX IF EXISTS idx_blacklisted_token;
ALTER TABLE blacklisted_token DROP COLUMN IF EXISTS token;
ALTER TABLE blacklisted_token ADD COLUMN IF NOT EXISTS jti VARCHAR(36) NOT NULL UNIQUE;
