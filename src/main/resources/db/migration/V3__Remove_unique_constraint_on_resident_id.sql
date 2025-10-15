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
DECLARE
    constraint_rec RECORD;
BEGIN
    -- Find and drop all unique constraints on resident_id column
    FOR constraint_rec IN
        SELECT tc.constraint_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage ccu
            ON tc.constraint_name = ccu.constraint_name
            AND tc.table_schema = ccu.table_schema
        WHERE tc.table_name = 'apartments'
          AND tc.constraint_type = 'UNIQUE'
          AND ccu.column_name = 'resident_id'
    LOOP
        EXECUTE 'ALTER TABLE apartments DROP CONSTRAINT IF EXISTS ' || constraint_rec.constraint_name;
    END LOOP;
END $$;
