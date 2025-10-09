-- Add FCM token column to residents table for push notifications

ALTER TABLE residents ADD COLUMN IF NOT EXISTS fcm_token VARCHAR(255);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_residents_fcm_token ON residents(fcm_token);
