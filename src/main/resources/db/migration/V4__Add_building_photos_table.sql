/*
  # Add Building Photos Table

  1. New Tables
    - `building_photos`
      - `id` (bigserial, primary key) - Unique identifier for each photo
      - `building_id` (text, foreign key) - Reference to the building
      - `photo_url` (text) - URL of the photo
      - `photo_order` (integer) - Order of the photo in the gallery
      - `description` (text) - Optional description of the photo
      - `created_at` (timestamp) - Timestamp when photo was added
      - `updated_at` (timestamp) - Timestamp when photo was last updated

  2. Changes
    - Add support for multiple photos per building
    - Each building can have multiple photos with ordering

  3. Security
    - Foreign key constraint ensures referential integrity
    - Cascade delete ensures photos are removed when building is deleted
*/

CREATE TABLE IF NOT EXISTS building_photos (
    id BIGSERIAL PRIMARY KEY,
    building_id TEXT NOT NULL,
    photo_url TEXT NOT NULL,
    photo_order INTEGER DEFAULT 0,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_building_photos_building
        FOREIGN KEY (building_id)
        REFERENCES buildings(building_id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_building_photos_building_id ON building_photos(building_id);
CREATE INDEX IF NOT EXISTS idx_building_photos_order ON building_photos(building_id, photo_order);
