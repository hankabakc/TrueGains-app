CREATE TABLE user_block (
    id BIGSERIAL PRIMARY KEY,
    blocker_id BIGINT NOT NULL,
    blocked_id BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_block_blocker FOREIGN KEY (blocker_id) REFERENCES app_user(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_block_blocked FOREIGN KEY (blocked_id) REFERENCES app_user(id) ON DELETE CASCADE,
    CONSTRAINT unique_user_block UNIQUE (blocker_id, blocked_id)
);

CREATE INDEX idx_user_block_blocker ON user_block(blocker_id);
CREATE INDEX idx_user_block_blocked ON user_block(blocked_id);
