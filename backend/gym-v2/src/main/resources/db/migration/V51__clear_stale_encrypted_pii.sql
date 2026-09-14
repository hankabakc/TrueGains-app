-- V51: Mevcut şifreleme anahtarıyla uyumsuz (eski anahtar / eski format) PII verilerinin temizlenmesi
-- Bu işlem, deşifre edilemeyen Base64 verilerini NULL'a çekerek kullanıcıların veriyi doğru anahtarla yeniden girmesini sağlar.

UPDATE client SET full_name = NULL, bio = NULL;
UPDATE coach SET full_name = NULL, bio = NULL;
