-- V54: Coach tablosuna max_clients kolonunun eklenmesi
ALTER TABLE coach ADD COLUMN IF NOT EXISTS max_clients INTEGER DEFAULT 10;
