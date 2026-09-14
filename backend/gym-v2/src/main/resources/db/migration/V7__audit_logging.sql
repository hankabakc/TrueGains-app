-- Güvenlik İzleme (Audit Log) Tablosu
CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    action VARCHAR(100) NOT NULL,
    user_email VARCHAR(255),
    ip_address VARCHAR(50),
    details TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_log_email ON audit_log(user_email);
CREATE INDEX idx_audit_log_action ON audit_log(action);
