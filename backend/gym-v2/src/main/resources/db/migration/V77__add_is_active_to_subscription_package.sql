-- V77: Paket soft-delete için is_active bayrağı
ALTER TABLE subscription_package ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;
