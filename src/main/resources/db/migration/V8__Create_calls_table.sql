/*
  # Create calls table

  1. New Tables
    - `calls`
      - `id` (bigint, primary key, auto increment)
      - `channel_id` (bigint, foreign key to channels)
      - `caller_id` (varchar, foreign key to residents)
      - `receiver_id` (varchar, foreign key to residents)
      - `started_at` (timestamp)
      - `ended_at` (timestamp)
      - `duration_seconds` (int)
      - `status` (varchar)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - No RLS needed as this is managed by backend
*/

CREATE TABLE IF NOT EXISTS calls (
    id BIGSERIAL PRIMARY KEY,
    channel_id BIGINT NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
    caller_id VARCHAR(255) NOT NULL REFERENCES residents(id_users) ON DELETE CASCADE,
    receiver_id VARCHAR(255) NOT NULL REFERENCES residents(id_users) ON DELETE CASCADE,
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    duration_seconds INTEGER,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_calls_channel_id ON calls(channel_id);
CREATE INDEX IF NOT EXISTS idx_calls_caller_id ON calls(caller_id);
CREATE INDEX IF NOT EXISTS idx_calls_receiver_id ON calls(receiver_id);
CREATE INDEX IF NOT EXISTS idx_calls_created_at ON calls(created_at DESC);
