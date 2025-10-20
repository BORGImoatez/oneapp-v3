/*
  # Add Building Details Fields

  1. Changes to buildings table
    - Add `number_of_floors` (integer) - Nombre d'étages
    - Add `building_state` (varchar) - État du bâtiment
    - Add `facade_width` (decimal) - Largeur de la façade en mètres
    - Add `land_area` (decimal) - Surface du terrain en m²
    - Add `land_width` (decimal) - Largeur du terrain en mètres
    - Add `built_area` (decimal) - Surface bâtie en m²
    - Add `has_elevator` (boolean) - Ascenseur présent
    - Add `has_handicap_access` (boolean) - Accès handicapé
    - Add `has_pool` (boolean) - Piscine présente
    - Add `has_cable_tv` (boolean) - Câble TV présent

  2. Notes
    - All new fields are nullable to support existing data
    - Default values set to false for boolean fields
    - Decimal fields use precision (10,2) for adequate space and accuracy
*/

-- Add general information fields
ALTER TABLE buildings
ADD COLUMN IF NOT EXISTS number_of_floors INTEGER,
ADD COLUMN IF NOT EXISTS building_state VARCHAR(100),
ADD COLUMN IF NOT EXISTS facade_width DECIMAL(10, 2);

-- Add specific information fields
ALTER TABLE buildings
ADD COLUMN IF NOT EXISTS land_area DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS land_width DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS built_area DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS has_elevator BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS has_handicap_access BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS has_pool BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS has_cable_tv BOOLEAN DEFAULT false;

-- Add comments for documentation
COMMENT ON COLUMN buildings.number_of_floors IS 'Nombre d''étages du bâtiment';
COMMENT ON COLUMN buildings.building_state IS 'État du bâtiment (Excellent, Bon, Moyen, À rénover, etc.)';
COMMENT ON COLUMN buildings.facade_width IS 'Largeur de la façade en mètres';
COMMENT ON COLUMN buildings.land_area IS 'Surface du terrain en m²';
COMMENT ON COLUMN buildings.land_width IS 'Largeur du terrain en mètres';
COMMENT ON COLUMN buildings.built_area IS 'Surface bâtie en m²';
COMMENT ON COLUMN buildings.has_elevator IS 'Indique si le bâtiment dispose d''un ascenseur';
COMMENT ON COLUMN buildings.has_handicap_access IS 'Indique si le bâtiment dispose d''un accès pour personnes handicapées';
COMMENT ON COLUMN buildings.has_pool IS 'Indique si le bâtiment dispose d''une piscine';
COMMENT ON COLUMN buildings.has_cable_tv IS 'Indique si le bâtiment dispose de la câble TV';
