ALTER TABLE app_user ADD COLUMN daily_ai_recipe_count INT DEFAULT 0;
ALTER TABLE app_user ADD COLUMN last_ai_recipe_date DATE;
ALTER TABLE app_user ADD COLUMN last_ai_recipe_suggestion TEXT;
