-- V95: Migrate remaining TIMESTAMP columns to TIMESTAMPTZ for Hibernate 7 compatibility

-- conversation table
ALTER TABLE conversation ALTER COLUMN created_at TYPE TIMESTAMPTZ;
ALTER TABLE conversation ALTER COLUMN last_message_at TYPE TIMESTAMPTZ;

-- message table
ALTER TABLE message ALTER COLUMN sent_at TYPE TIMESTAMPTZ;

-- pairing_request table
ALTER TABLE pairing_request ALTER COLUMN created_at TYPE TIMESTAMPTZ;
ALTER TABLE pairing_request ALTER COLUMN updated_at TYPE TIMESTAMPTZ;

-- diet_program table
ALTER TABLE diet_program ALTER COLUMN created_at TYPE TIMESTAMPTZ;
ALTER TABLE diet_program ALTER COLUMN updated_at TYPE TIMESTAMPTZ;

-- food table
ALTER TABLE food ALTER COLUMN created_at TYPE TIMESTAMPTZ;

-- meal_entry table
ALTER TABLE meal_entry ALTER COLUMN taken_datetime TYPE TIMESTAMPTZ;

-- measurements table
ALTER TABLE measurements ALTER COLUMN created_at TYPE TIMESTAMPTZ;
