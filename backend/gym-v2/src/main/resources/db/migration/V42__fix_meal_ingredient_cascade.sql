-- V42: Fix ck_meal_ingredient_target violation on recipe deletion
-- Changes the ON DELETE policy from SET NULL to CASCADE for recipe and user_recipe foreign keys.

ALTER TABLE meal_ingredient DROP CONSTRAINT IF EXISTS fk_meal_ingredient_recipe;
ALTER TABLE meal_ingredient DROP CONSTRAINT IF EXISTS fk_meal_ingredient_user_recipe;

ALTER TABLE meal_ingredient ADD CONSTRAINT fk_meal_ingredient_recipe 
  FOREIGN KEY (recipe_id) REFERENCES recipe(id) ON DELETE CASCADE;

ALTER TABLE meal_ingredient ADD CONSTRAINT fk_meal_ingredient_user_recipe 
  FOREIGN KEY (user_recipe_id) REFERENCES user_recipe(id) ON DELETE CASCADE;
