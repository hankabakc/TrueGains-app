ALTER TABLE message ADD COLUMN package_id BIGINT;
ALTER TABLE message ADD COLUMN package_name VARCHAR(255);
ALTER TABLE message ADD COLUMN package_price NUMERIC(12,2);
