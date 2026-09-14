-- Measurement tablosuna antrenörle paylaşım durumunu tutan kolon eklendi.
-- Varsayılan değer false olarak atandı ve mevcut kayıtlar için de false olarak güncellendi.
ALTER TABLE measurements ADD COLUMN is_shared_with_coach BOOLEAN NOT NULL DEFAULT FALSE;
