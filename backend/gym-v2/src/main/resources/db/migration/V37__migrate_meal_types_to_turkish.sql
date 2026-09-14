-- V37: Migrate Meal Types from English to Turkish
UPDATE meal SET meal_type = 'KAHVALTI' WHERE meal_type = 'BREAKFAST';
UPDATE meal SET meal_type = 'OGLE_YEMEGI' WHERE meal_type = 'LUNCH';
UPDATE meal SET meal_type = 'AKSAM_YEMEGI' WHERE meal_type = 'DINNER';
UPDATE meal SET meal_type = 'OTHER' WHERE meal_type = 'OTHER';

-- Also update any future references if needed, but the VARCHAR(50) is enough.
