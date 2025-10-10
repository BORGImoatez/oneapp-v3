-- Create notifications table to store notification history

CREATE TABLE IF NOT EXISTS notifications (
    id BIGSERIAL PRIMARY KEY,
    resident_id VARCHAR(255) NOT NULL,
    building_id VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    channel_id BIGINT,
    vote_id BIGINT,
    document_id BIGINT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP,

    CONSTRAINT fk_notifications_resident
        FOREIGN KEY (resident_id) REFERENCES residents(id_users) ON DELETE CASCADE,
    CONSTRAINT fk_notifications_building
        FOREIGN KEY (building_id) REFERENCES buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT fk_notifications_channel
        FOREIGN KEY (channel_id) REFERENCES channels(id) ON DELETE CASCADE
);

CREATE INDEX idx_notifications_resident_created ON notifications(resident_id, created_at DESC);
CREATE INDEX idx_notifications_building ON notifications(building_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_type ON notifications(type);
