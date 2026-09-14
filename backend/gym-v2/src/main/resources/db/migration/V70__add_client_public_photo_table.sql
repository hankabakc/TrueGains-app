-- Flyway Migration: Add client_public_photo table for relationsal gallery storage
CREATE TABLE client_public_photo (
    client_id BIGINT NOT NULL,
    photo_url VARCHAR(500) NOT NULL,
    CONSTRAINT fk_client_public_photo_client FOREIGN KEY (client_id) REFERENCES client (user_id) ON DELETE CASCADE
);

CREATE INDEX idx_client_public_photo_client_id ON client_public_photo(client_id);
