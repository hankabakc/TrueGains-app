-- payment_transaction tablosuna package_id ekleme ve foreign key oluşturma
ALTER TABLE payment_transaction ADD COLUMN package_id BIGINT;
ALTER TABLE payment_transaction ADD CONSTRAINT fk_payment_transaction_package FOREIGN KEY (package_id) REFERENCES subscription_package(id);
