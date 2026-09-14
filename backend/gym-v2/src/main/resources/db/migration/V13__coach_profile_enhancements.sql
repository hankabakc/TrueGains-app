-- V13__coach_profile_enhancements.sql

-- Add show_subscriber_count to coach table
ALTER TABLE coach ADD COLUMN show_subscriber_count BOOLEAN DEFAULT false;

-- Create coach_gallery table
CREATE TABLE coach_gallery (
    id BIGSERIAL PRIMARY KEY,
    coach_id BIGINT NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    is_student_progress BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_coach_gallery_coach FOREIGN KEY (coach_id) REFERENCES coach(user_id) ON DELETE CASCADE
);

-- Create coach_review table
CREATE TABLE coach_review (
    id BIGSERIAL PRIMARY KEY,
    coach_id BIGINT NOT NULL,
    client_id BIGINT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_coach_review_coach FOREIGN KEY (coach_id) REFERENCES coach(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_coach_review_client FOREIGN KEY (client_id) REFERENCES client(user_id) ON DELETE CASCADE,
    -- A client can leave only one review per coach, they can update it instead of inserting multiples.
    CONSTRAINT uq_coach_review_coach_client UNIQUE (coach_id, client_id)
);
