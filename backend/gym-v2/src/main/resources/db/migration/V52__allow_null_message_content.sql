-- V52: Mesaj içeriği (content) kolonunun nullable yapılması
-- Sadece fotoğraf gönderilen mesajlarda content null olabileceği için NOT NULL kısıtı kaldırılmıştır.

ALTER TABLE message ALTER COLUMN content DROP NOT NULL;
