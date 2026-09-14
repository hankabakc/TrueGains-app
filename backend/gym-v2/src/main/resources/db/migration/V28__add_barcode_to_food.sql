-- V28: Add barcode to food table for OpenFoodFacts integration
ALTER TABLE food ADD COLUMN barcode VARCHAR(50);
CREATE INDEX idx_food_barcode ON food(barcode);
