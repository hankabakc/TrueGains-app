-- V58: training_blocks tablosuna template_id kolonunun eklenmesi
-- Bu kolon, bir şablondan türetilen atamaların hangi şablona ait olduğunu takip etmek için kullanılır.
-- Aynı isme sahip farklı şablonların karışmasını önler.

ALTER TABLE training_blocks ADD COLUMN template_id BIGINT;
COMMENT ON COLUMN training_blocks.template_id IS 'Bu programın türetildiği şablonun ID''si (is_template = false ise doludur)';
