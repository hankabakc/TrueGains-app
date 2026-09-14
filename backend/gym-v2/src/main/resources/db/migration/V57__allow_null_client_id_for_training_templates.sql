-- V57: training_blocks tablosundaki client_id kısıtlamasının esnetilmesi
-- Şablonlarda (is_template = true) client_id null olmalıdır.
-- Bu nedenle NOT NULL kısıtlamasını kaldırıyoruz.

ALTER TABLE training_blocks ALTER COLUMN client_id DROP NOT NULL;
