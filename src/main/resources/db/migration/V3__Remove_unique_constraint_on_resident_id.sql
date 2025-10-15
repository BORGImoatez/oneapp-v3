/*
  # Remove Unique Constraint on Apartment resident_id

  1. Changes
    - Drop the unique constraint on `apartments.resident_id`
    - This allows a single resident to have multiple apartments across different buildings

  2. Reason
    - Business requirement: Residents can own/rent apartments in multiple buildings
    - The relationship changes from OneToOne to ManyToOne (Apartment -> Resident)
    - Uniqueness is maintained through the ResidentBuilding table which links residents to buildings and their specific apartments

  3. Security
    - No RLS changes needed
    - This is a structural change only
*/

-- Drop the unique constraint if it exists
ALTER TABLE apartments DROP CONSTRAINT IF EXISTS ukd7i18j1axm6b148sy9kqfjdsh;

-- Also drop any other unique constraint on resident_id that might exist
DO $$
BEGIN
    -- Drop all unique constraints on resident_id column
    PERFORM constraint_name
    FROM information_schema.table_constraints
    WHERE table_name = 'apartments'
      AND constraint_type = 'UNIQUE'
      AND constraint_name IN (
          SELECT constraint_name
          FROM information_schema.constraint_column_usage
          WHERE table_name = 'apartments' AND column_name = 'resident_id'
      );

    -- If found, drop them
    FOR constraint_record IN
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'apartments'
          AND constraint_type = 'UNIQUE'
          AND constraint_name IN (
              SELECT constraint_name
              FROM information_schema.constraint_column_usage
              WHERE table_name = 'apartments' AND column_name = 'resident_id'
          )
    LOOP
        EXECUTE 'ALTER TABLE apartments DROP CONSTRAINT IF EXISTS ' || constraint_record.constraint_name;
    END LOOP;
END $$;
