-- V34: Meal Template Geliştirmeleri (Çoklu Öğün Tipleri ve Override Desteği)

-- Meal Template Ingredient tablosuna ignore_override kolonu eklenmesi
ALTER TABLE meal_template_ingredient ADD COLUMN ignore_override BOOLEAN DEFAULT FALSE NOT NULL;

-- Meal Template Applicable Types tablosu (Çoklu öğün etiketleri için)
CREATE TABLE meal_template_applicable_types (
    meal_template_id BIGINT NOT NULL,
    meal_type VARCHAR(50) NOT NULL,
    CONSTRAINT fk_meal_template_applicable_types_template FOREIGN KEY (meal_template_id) REFERENCES meal_template(id)
);

CREATE INDEX idx_meal_template_applicable_types_id ON meal_template_applicable_types(meal_template_id);
