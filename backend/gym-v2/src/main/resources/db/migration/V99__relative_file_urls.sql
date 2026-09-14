-- Dosya adresleri sunucu adı olmadan saklanır: adres yüklendiği günkü host'a çakılırsa
-- alan adı/IP değişiminde tüm görseller kırılır. Sunucu adını istemci ekler.
-- Yalnızca kendi dosya ucumuzu gösteren kayıtlar kırpılır; dış adresler (tohum
-- verisindeki pravatar/unsplash) korunur.
UPDATE app_user SET profile_photo_url = regexp_replace(profile_photo_url, '^https?://[^/]+', '')
 WHERE profile_photo_url ~ '^https?://[^/]+/api/v1/files/';

UPDATE client SET profile_photo_url = regexp_replace(profile_photo_url, '^https?://[^/]+', '')
 WHERE profile_photo_url ~ '^https?://[^/]+/api/v1/files/';

UPDATE coach SET profile_photo_url = regexp_replace(profile_photo_url, '^https?://[^/]+', '')
 WHERE profile_photo_url ~ '^https?://[^/]+/api/v1/files/';

UPDATE client SET cover_photo_url = regexp_replace(cover_photo_url, '^https?://[^/]+', '')
 WHERE cover_photo_url ~ '^https?://[^/]+/api/v1/files/';

UPDATE coach SET cover_photo_url = regexp_replace(cover_photo_url, '^https?://[^/]+', '')
 WHERE cover_photo_url ~ '^https?://[^/]+/api/v1/files/';

UPDATE message SET attachment_url = regexp_replace(attachment_url, '^https?://[^/]+', '')
 WHERE attachment_url ~ '^https?://[^/]+/api/v1/files/';

UPDATE client_gallery SET image_url = regexp_replace(image_url, '^https?://[^/]+', '')
 WHERE image_url ~ '^https?://[^/]+/api/v1/files/';

UPDATE coach_gallery SET image_url = regexp_replace(image_url, '^https?://[^/]+', '')
 WHERE image_url ~ '^https?://[^/]+/api/v1/files/';

UPDATE client_progress_photo SET image_url = regexp_replace(image_url, '^https?://[^/]+', '')
 WHERE image_url ~ '^https?://[^/]+/api/v1/files/';

UPDATE client_public_photo SET photo_url = regexp_replace(photo_url, '^https?://[^/]+', '')
 WHERE photo_url ~ '^https?://[^/]+/api/v1/files/';

UPDATE coach_certificate SET image_url = regexp_replace(image_url, '^https?://[^/]+', '')
 WHERE image_url ~ '^https?://[^/]+/api/v1/files/';

UPDATE coach_student_progress SET before_image_url = regexp_replace(before_image_url, '^https?://[^/]+', '')
 WHERE before_image_url ~ '^https?://[^/]+/api/v1/files/';

UPDATE coach_student_progress SET after_image_url = regexp_replace(after_image_url, '^https?://[^/]+', '')
 WHERE after_image_url ~ '^https?://[^/]+/api/v1/files/';

UPDATE meal_entry SET photo_url = regexp_replace(photo_url, '^https?://[^/]+', '')
 WHERE photo_url ~ '^https?://[^/]+/api/v1/files/';
