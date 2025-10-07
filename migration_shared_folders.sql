-- Migration: Add shared folders functionality
-- This migration adds the ability for admins to create shared folders visible by all apartments in a building

-- Step 1: Add is_shared column to folders table
ALTER TABLE folders
ADD COLUMN IF NOT EXISTS is_shared BOOLEAN DEFAULT false;

-- Step 2: Set default value for existing folders (all private by default)
UPDATE folders
SET is_shared = false
WHERE is_shared IS NULL;

-- Step 3: Make is_shared NOT NULL with default false
ALTER TABLE folders
ALTER COLUMN is_shared SET DEFAULT false;

ALTER TABLE folders
ALTER COLUMN is_shared SET NOT NULL;

-- Step 4: Create index on is_shared for performance
CREATE INDEX IF NOT EXISTS idx_folders_is_shared
ON folders(is_shared);

-- Step 5: Create composite index for filtering by building and is_shared
CREATE INDEX IF NOT EXISTS idx_folders_building_shared
ON folders(building_id, is_shared);

-- Step 6: Create composite index for filtering by building and apartment
CREATE INDEX IF NOT EXISTS idx_folders_building_apartment
ON folders(building_id, apartment_id);

-- Verification queries
-- SELECT COUNT(*) as total_folders,
--        SUM(CASE WHEN is_shared = true THEN 1 ELSE 0 END) as shared_folders,
--        SUM(CASE WHEN is_shared = false THEN 1 ELSE 0 END) as private_folders
-- FROM folders;
