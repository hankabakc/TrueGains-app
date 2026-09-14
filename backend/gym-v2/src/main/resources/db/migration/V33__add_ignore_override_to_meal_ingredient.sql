-- V33: Add ignore_override column to meal_ingredient
ALTER TABLE meal_ingredient ADD COLUMN ignore_override BOOLEAN DEFAULT FALSE;
