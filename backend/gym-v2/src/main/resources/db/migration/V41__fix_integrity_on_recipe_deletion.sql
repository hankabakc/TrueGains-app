-- V41: Add ON DELETE SET NULL to Recipe references for data integrity

-- 1. Meal Ingredient (Diet Logs)
ALTER TABLE meal_ingredient DROP CONSTRAINT IF EXISTS fk_meal_ingredient_recipe;
ALTER TABLE meal_ingredient DROP CONSTRAINT IF EXISTS fk_meal_ingredient_user_recipe;

ALTER TABLE meal_ingredient ADD CONSTRAINT fk_meal_ingredient_recipe 
    FOREIGN KEY (recipe_id) REFERENCES recipe(id) ON DELETE SET NULL;
ALTER TABLE meal_ingredient ADD CONSTRAINT fk_meal_ingredient_user_recipe 
    FOREIGN KEY (user_recipe_id) REFERENCES user_recipe(id) ON DELETE SET NULL;

-- 2. Meal Template Ingredient (Meal Templates)
ALTER TABLE meal_template_ingredient DROP CONSTRAINT IF EXISTS fk_meal_template_ingredient_recipe;
ALTER TABLE meal_template_ingredient DROP CONSTRAINT IF EXISTS fk_meal_template_ingredient_user_recipe;

ALTER TABLE meal_template_ingredient ADD CONSTRAINT fk_meal_template_ingredient_recipe 
    FOREIGN KEY (recipe_id) REFERENCES recipe(id) ON DELETE SET NULL;
ALTER TABLE meal_template_ingredient ADD CONSTRAINT fk_meal_template_ingredient_user_recipe 
    FOREIGN KEY (user_recipe_id) REFERENCES user_recipe(id) ON DELETE SET NULL;
