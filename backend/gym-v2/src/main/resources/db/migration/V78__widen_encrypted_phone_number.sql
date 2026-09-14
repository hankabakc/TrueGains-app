-- V78: Widen encrypted phone_number column in app_user table to prevent encryption length overflow
ALTER TABLE app_user ALTER COLUMN phone_number TYPE VARCHAR(500);
