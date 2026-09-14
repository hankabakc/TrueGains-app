-- V26: Nutrition Module - Add Meal Type to Meal Entry

-- Öğün girdilerini Breakfast, Lunch vb. olarak ayırmak için meal_type ekliyoruz.
ALTER TABLE meal_entry ADD COLUMN meal_type VARCHAR(50) DEFAULT 'OTHER' NOT NULL;
