-- V68__create_client_gallery_and_student_progress.sql
-- Sporcu galerisi ve antrenör öğrenci gelişim (Before-After) tablolarının oluşturulması

-- 1. Client Gallery Tablosu
CREATE TABLE client_gallery (
    id BIGSERIAL PRIMARY KEY,
    client_id BIGINT NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_client_gallery_client FOREIGN KEY (client_id) REFERENCES client(user_id) ON DELETE CASCADE
);

-- 2. Coach Student Progress (Before-After) Tablosu
CREATE TABLE coach_student_progress (
    id BIGSERIAL PRIMARY KEY,
    coach_id BIGINT NOT NULL,
    client_id BIGINT NOT NULL,
    student_nickname VARCHAR(255) NOT NULL,
    before_image_url VARCHAR(500) NOT NULL,
    after_image_url VARCHAR(500) NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_student_progress_coach FOREIGN KEY (coach_id) REFERENCES coach(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_student_progress_client FOREIGN KEY (client_id) REFERENCES client(user_id) ON DELETE CASCADE
);

-- 3. App User Tablosuna Profil Fotoğrafı Alanı Eklenmesi
ALTER TABLE app_user ADD COLUMN profile_photo_url VARCHAR(500);
