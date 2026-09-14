-- V60: Add original_template_id column to diet_program for duplicate assignment checks
ALTER TABLE diet_program ADD COLUMN original_template_id BIGINT;
