-- V39: Add Recipe support to MealIngredient

-- Update meal_ingredient table (Diet Program Meals)
ALTER TABLE meal_ingredient ALTER COLUMN food_id DROP NOT NULL;
ALTER TABLE meal_ingredient ADD COLUMN recipe_id BIGINT;
ALTER TABLE meal_ingredient ADD COLUMN user_recipe_id BIGINT;

ALTER TABLE meal_ingredient ADD CONSTRAINT fk_meal_ingredient_recipe FOREIGN KEY (recipe_id) REFERENCES recipe(id);
ALTER TABLE meal_ingredient ADD CONSTRAINT fk_meal_ingredient_user_recipe FOREIGN KEY (user_recipe_id) REFERENCES user_recipe(id);

ALTER TABLE meal_ingredient ADD CONSTRAINT ck_meal_ingredient_target CHECK (
    (food_id IS NOT NULL AND recipe_id IS NULL AND user_recipe_id IS NULL) OR
    (food_id IS NULL AND recipe_id IS NOT NULL AND user_recipe_id IS NULL) OR
    (food_id IS NULL AND recipe_id IS NULL AND user_recipe_id IS NOT NULL)
);
