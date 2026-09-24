-- G-76: diyet planı belgesi internetsiz kuyruktan ya da zaman aşımında yeniden gelirse ikinci kez yazılmasın
-- (G-89 deseni). Son uygulanan belgenin cihaz kimliği tutulur; aynı kimlikle gelen istek uygulanmış hâli alır.
ALTER TABLE diet_program ADD COLUMN last_edit_id VARCHAR(36);
