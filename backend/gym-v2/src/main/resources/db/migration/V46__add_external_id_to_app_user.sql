-- V46: app_user tablosuna external_id (UUID) ekleme
ALTER TABLE app_user ADD COLUMN external_id VARCHAR(36);

-- Mevcut kullanıcılar için UUID üretme (PostgreSQL 17+ yerleşik gen_random_uuid() kullanır)
UPDATE app_user SET external_id = gen_random_uuid()::text WHERE external_id IS NULL;

-- Sütunu zorunlu ve benzersiz yapma
ALTER TABLE app_user ALTER COLUMN external_id SET NOT NULL;
ALTER TABLE app_user ADD CONSTRAINT uk_app_user_external_id UNIQUE (external_id);
