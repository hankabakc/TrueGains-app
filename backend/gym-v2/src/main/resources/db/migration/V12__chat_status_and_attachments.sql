-- Add status and attachment_url columns to message table
ALTER TABLE message ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'SENT';
ALTER TABLE message ADD COLUMN attachment_url VARCHAR(1024);

-- Remove the old boolean is_read as it is superseded by status
-- (Migrate data if necessary before dropping, but since it's a new or fresh schema, dropping is fine)
ALTER TABLE message DROP COLUMN IF EXISTS is_read;
