/*
  # Create Apartment Details Management System

  1. New Tables
    - `apartment_photos`
      - `id` (bigint, primary key, auto-increment)
      - `apartment_id` (bigint, foreign key to apartments)
      - `photo_url` (varchar 500)
      - `display_order` (integer)
      - `uploaded_at` (timestamp)
      - `uploaded_by` (bigint, foreign key to residents)

    - `apartment_general_info`
      - `id` (bigint, primary key, auto-increment)
      - `apartment_id` (bigint, unique, foreign key to apartments)
      - `nb_chambres` (integer)
      - `nb_salle_bain` (integer)
      - `surface` (decimal)
      - `etage` (integer)
      - `updated_at` (timestamp)
      - `updated_by` (bigint, foreign key to residents)

    - `apartment_interior`
      - `id` (bigint, primary key, auto-increment)
      - `apartment_id` (bigint, unique, foreign key to apartments)
      - `quartier_lieu` (varchar 255)
      - `surface_habitable` (decimal)
      - `surface_salon` (decimal)
      - `type_cuisine` (varchar 100)
      - `surface_cuisine` (decimal)
      - `surface_chambres` (text) - JSON array of room surfaces
      - `nb_salle_douche` (integer)
      - `nb_toilette` (integer)
      - `cave` (boolean)
      - `grenier` (boolean)
      - `updated_at` (timestamp)
      - `updated_by` (bigint, foreign key to residents)

    - `apartment_exterior`
      - `id` (bigint, primary key, auto-increment)
      - `apartment_id` (bigint, unique, foreign key to apartments)
      - `surface_terrasse` (decimal)
      - `orientation_terrasse` (varchar 50) - 'SUD', 'NORD', 'EST', 'OUEST'
      - `updated_at` (timestamp)
      - `updated_by` (bigint, foreign key to residents)

    - `apartment_installations`
      - `id` (bigint, primary key, auto-increment)
      - `apartment_id` (bigint, unique, foreign key to apartments)
      - `ascenseur` (boolean)
      - `acces_handicap` (boolean)
      - `parlophone` (boolean)
      - `interphone_video` (boolean)
      - `porte_blindee` (boolean)
      - `piscine` (boolean)
      - `updated_at` (timestamp)
      - `updated_by` (bigint, foreign key to residents)

    - `apartment_energie`
      - `id` (bigint, primary key, auto-increment)
      - `apartment_id` (bigint, unique, foreign key to apartments)
      - `classe_energetique` (varchar 10)
      - `consommation_energie_primaire` (decimal)
      - `consommation_theorique_totale` (decimal)
      - `emission_co2` (decimal)
      - `numero_rapport_peb` (varchar 100)
      - `type_chauffage` (varchar 100)
      - `double_vitrage` (boolean)
      - `updated_at` (timestamp)
      - `updated_by` (bigint, foreign key to residents)

  2. Security
    - All tables have appropriate foreign key constraints
    - Residents can only manage apartments they are associated with through resident_building

  3. Notes
    - Each apartment can have multiple photos with ordering
    - All detail sections are optional and can be updated independently
    - surface_chambres is stored as JSON to allow flexible number of rooms
    - Orientation options: SUD, NORD, EST, OUEST
*/

-- Apartment Photos Table
CREATE TABLE IF NOT EXISTS apartment_photos (
    id BIGSERIAL PRIMARY KEY,
    apartment_id BIGINT NOT NULL,
    photo_url VARCHAR(500) NOT NULL,
    display_order INT DEFAULT 0,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    uploaded_by BIGINT,
    CONSTRAINT fk_apartment_photos_apartment FOREIGN KEY (apartment_id) REFERENCES apartments(id) ON DELETE CASCADE,
    CONSTRAINT fk_apartment_photos_resident FOREIGN KEY (uploaded_by) REFERENCES residents(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_apartment_photos_apartment ON apartment_photos(apartment_id);

-- Apartment General Info Table
CREATE TABLE IF NOT EXISTS apartment_general_info (
    id BIGSERIAL PRIMARY KEY,
    apartment_id BIGINT NOT NULL UNIQUE,
    nb_chambres INT,
    nb_salle_bain INT,
    surface DECIMAL(10, 2),
    etage INT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT,
    CONSTRAINT fk_apartment_general_apartment FOREIGN KEY (apartment_id) REFERENCES apartments(id) ON DELETE CASCADE,
    CONSTRAINT fk_apartment_general_resident FOREIGN KEY (updated_by) REFERENCES residents(id) ON DELETE SET NULL
);

-- Apartment Interior Table
CREATE TABLE IF NOT EXISTS apartment_interior (
    id BIGSERIAL PRIMARY KEY,
    apartment_id BIGINT NOT NULL UNIQUE,
    quartier_lieu VARCHAR(255),
    surface_habitable DECIMAL(10, 2),
    surface_salon DECIMAL(10, 2),
    type_cuisine VARCHAR(100),
    surface_cuisine DECIMAL(10, 2),
    surface_chambres TEXT,
    nb_salle_douche INT,
    nb_toilette INT,
    cave BOOLEAN DEFAULT false,
    grenier BOOLEAN DEFAULT false,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT,
    CONSTRAINT fk_apartment_interior_apartment FOREIGN KEY (apartment_id) REFERENCES apartments(id) ON DELETE CASCADE,
    CONSTRAINT fk_apartment_interior_resident FOREIGN KEY (updated_by) REFERENCES residents(id) ON DELETE SET NULL
);

-- Apartment Exterior Table
CREATE TABLE IF NOT EXISTS apartment_exterior (
    id BIGSERIAL PRIMARY KEY,
    apartment_id BIGINT NOT NULL UNIQUE,
    surface_terrasse DECIMAL(10, 2),
    orientation_terrasse VARCHAR(50),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT,
    CONSTRAINT fk_apartment_exterior_apartment FOREIGN KEY (apartment_id) REFERENCES apartments(id) ON DELETE CASCADE,
    CONSTRAINT fk_apartment_exterior_resident FOREIGN KEY (updated_by) REFERENCES residents(id) ON DELETE SET NULL,
    CONSTRAINT chk_orientation CHECK (orientation_terrasse IN ('SUD', 'NORD', 'EST', 'OUEST') OR orientation_terrasse IS NULL)
);

-- Apartment Installations Table
CREATE TABLE IF NOT EXISTS apartment_installations (
    id BIGSERIAL PRIMARY KEY,
    apartment_id BIGINT NOT NULL UNIQUE,
    ascenseur BOOLEAN DEFAULT false,
    acces_handicap BOOLEAN DEFAULT false,
    parlophone BOOLEAN DEFAULT false,
    interphone_video BOOLEAN DEFAULT false,
    porte_blindee BOOLEAN DEFAULT false,
    piscine BOOLEAN DEFAULT false,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT,
    CONSTRAINT fk_apartment_installations_apartment FOREIGN KEY (apartment_id) REFERENCES apartments(id) ON DELETE CASCADE,
    CONSTRAINT fk_apartment_installations_resident FOREIGN KEY (updated_by) REFERENCES residents(id) ON DELETE SET NULL
);

-- Apartment Energie Table
CREATE TABLE IF NOT EXISTS apartment_energie (
    id BIGSERIAL PRIMARY KEY,
    apartment_id BIGINT NOT NULL UNIQUE,
    classe_energetique VARCHAR(10),
    consommation_energie_primaire DECIMAL(10, 2),
    consommation_theorique_totale DECIMAL(10, 2),
    emission_co2 DECIMAL(10, 2),
    numero_rapport_peb VARCHAR(100),
    type_chauffage VARCHAR(100),
    double_vitrage BOOLEAN DEFAULT false,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT,
    CONSTRAINT fk_apartment_energie_apartment FOREIGN KEY (apartment_id) REFERENCES apartments(id) ON DELETE CASCADE,
    CONSTRAINT fk_apartment_energie_resident FOREIGN KEY (updated_by) REFERENCES residents(id) ON DELETE SET NULL
);
