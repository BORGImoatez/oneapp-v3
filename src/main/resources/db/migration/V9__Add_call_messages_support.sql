/*
  # Add Call Messages Support

  This migration adds support for call messages in the messages table.

  1. Changes
    - Add `call_id` column to `messages` table to link messages to calls
    - This allows creating messages when calls are missed, rejected, or completed

  2. Purpose
    - Display call history in chat conversations
    - Show missed calls with date, time, and recall button
    - Track all call interactions within conversations
*/

-- Add call_id column to messages table
ALTER TABLE messages ADD COLUMN IF NOT EXISTS call_id BIGINT;

-- Add foreign key constraint
ALTER TABLE messages
ADD CONSTRAINT fk_messages_call_id
FOREIGN KEY (call_id)
REFERENCES calls(id)
ON DELETE SET NULL;

-- Add index for better performance when querying call messages
CREATE INDEX IF NOT EXISTS idx_messages_call_id ON messages(call_id);
