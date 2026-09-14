ALTER TABLE app_user ADD COLUMN fcm_token TEXT;
COMMENT ON COLUMN app_user.fcm_token IS 'Firebase Cloud Messaging cihaz token''ı';
