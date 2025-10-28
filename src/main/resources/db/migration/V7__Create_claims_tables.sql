/*
  # Module de Déclaration de Sinistres

  ## Description
  Ce module permet aux résidents de déclarer des sinistres affectant leurs appartements.
  Les administrateurs d'immeubles reçoivent des notifications push pour chaque nouveau sinistre.
  Les résidents des appartements affectés peuvent aussi consulter et recevoir des notifications.

  ## 1. Nouvelles Tables
    - `claims` (sinistres)
      - `id` (bigint, primary key) - Identifiant unique du sinistre
      - `apartment_id` (bigint) - Appartement déclarant le sinistre
      - `building_id` (bigint) - Immeuble concerné
      - `reporter_id` (bigint) - Résident déclarant le sinistre
      - `claim_types` (text[]) - Types de sinistres (array pour choix multiples)
      - `cause` (text) - Cause du sinistre
      - `description` (text) - Description détaillée des dégâts
      - `insurance_company` (text) - Compagnie d'assurance
      - `insurance_policy_number` (text) - Numéro de police d'assurance
      - `status` (varchar) - Statut du sinistre (PENDING, IN_PROGRESS, RESOLVED, CLOSED)
      - `created_at` (timestamptz) - Date de création
      - `updated_at` (timestamptz) - Date de dernière modification

    - `claim_affected_apartments` - Appartements touchés par le sinistre
      - `id` (bigint, primary key)
      - `claim_id` (bigint) - Référence au sinistre
      - `apartment_id` (bigint) - Appartement affecté
      - `created_at` (timestamptz)

    - `claim_photos` - Photos du sinistre
      - `id` (bigint, primary key)
      - `claim_id` (bigint) - Référence au sinistre
      - `photo_url` (text) - URL de la photo
      - `photo_order` (integer) - Ordre d'affichage
      - `created_at` (timestamptz)

  ## 2. Indexes
    - Index sur claim_id pour les performances
    - Index sur building_id pour filtrage rapide
    - Index sur apartment_id pour recherche par appartement
    - Index sur status pour filtrage par statut

  ## 3. Sécurité
    - RLS activé sur toutes les tables
    - Les résidents peuvent créer des sinistres pour leur appartement
    - Les résidents peuvent voir les sinistres de leur appartement ou qui affectent leur appartement
    - Les admins de l'immeuble peuvent voir tous les sinistres de leur immeuble
    - Seul le créateur peut modifier son sinistre (dans les 24h)
    - Les admins peuvent modifier le statut des sinistres

  ## 4. Notes Importantes
    - Les types de sinistres sont stockés en array pour permettre choix multiples
    - Les photos sont optionnelles
    - Les notifications push sont gérées via le système existant
*/

-- Table principale des sinistres
CREATE TABLE IF NOT EXISTS claims (
    id BIGSERIAL PRIMARY KEY,
    apartment_id BIGINT NOT NULL REFERENCES apartment(id) ON DELETE CASCADE,
    building_id BIGINT NOT NULL REFERENCES building(id) ON DELETE CASCADE,
    reporter_id BIGINT NOT NULL REFERENCES resident(id) ON DELETE CASCADE,
    claim_types TEXT[] NOT NULL,
    cause TEXT NOT NULL,
    description TEXT NOT NULL,
    insurance_company TEXT,
    insurance_policy_number TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table des appartements affectés
CREATE TABLE IF NOT EXISTS claim_affected_apartments (
    id BIGSERIAL PRIMARY KEY,
    claim_id BIGINT NOT NULL REFERENCES claims(id) ON DELETE CASCADE,
    apartment_id BIGINT NOT NULL REFERENCES apartment(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(claim_id, apartment_id)
);

-- Table des photos de sinistres
CREATE TABLE IF NOT EXISTS claim_photos (
    id BIGSERIAL PRIMARY KEY,
    claim_id BIGINT NOT NULL REFERENCES claims(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    photo_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes pour optimisation des performances
CREATE INDEX IF NOT EXISTS idx_claims_building_id ON claims(building_id);
CREATE INDEX IF NOT EXISTS idx_claims_apartment_id ON claims(apartment_id);
CREATE INDEX IF NOT EXISTS idx_claims_reporter_id ON claims(reporter_id);
CREATE INDEX IF NOT EXISTS idx_claims_status ON claims(status);
CREATE INDEX IF NOT EXISTS idx_claims_created_at ON claims(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_claim_affected_apartments_claim_id ON claim_affected_apartments(claim_id);
CREATE INDEX IF NOT EXISTS idx_claim_affected_apartments_apartment_id ON claim_affected_apartments(apartment_id);
CREATE INDEX IF NOT EXISTS idx_claim_photos_claim_id ON claim_photos(claim_id);

-- Activer RLS sur toutes les tables
ALTER TABLE claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE claim_affected_apartments ENABLE ROW LEVEL SECURITY;
ALTER TABLE claim_photos ENABLE ROW LEVEL SECURITY;

-- Politique pour créer un sinistre (résidents authentifiés)
CREATE POLICY "Residents can create claims for their apartments"
    ON claims FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM resident_building rb
            WHERE rb.resident_id = auth.uid()
            AND rb.apartment_id = apartment_id
            AND rb.building_id = building_id
        )
    );

-- Politique pour voir les sinistres
CREATE POLICY "Users can view claims they reported or that affect their apartment"
    ON claims FOR SELECT
    TO authenticated
    USING (
        reporter_id = auth.uid()
        OR apartment_id IN (
            SELECT rb.apartment_id
            FROM resident_building rb
            WHERE rb.resident_id = auth.uid()
        )
        OR id IN (
            SELECT caa.claim_id
            FROM claim_affected_apartments caa
            INNER JOIN resident_building rb ON rb.apartment_id = caa.apartment_id
            WHERE rb.resident_id = auth.uid()
        )
        OR building_id IN (
            SELECT rb.building_id
            FROM resident_building rb
            WHERE rb.resident_id = auth.uid()
            AND rb.role = 'ADMIN'
        )
    );

-- Politique pour modifier un sinistre (seulement le créateur dans les 24h ou admin)
CREATE POLICY "Users can update their own recent claims or admins can update any"
    ON claims FOR UPDATE
    TO authenticated
    USING (
        (reporter_id = auth.uid() AND created_at > NOW() - INTERVAL '24 hours')
        OR building_id IN (
            SELECT rb.building_id
            FROM resident_building rb
            WHERE rb.resident_id = auth.uid()
            AND rb.role = 'ADMIN'
        )
    )
    WITH CHECK (
        (reporter_id = auth.uid() AND created_at > NOW() - INTERVAL '24 hours')
        OR building_id IN (
            SELECT rb.building_id
            FROM resident_building rb
            WHERE rb.resident_id = auth.uid()
            AND rb.role = 'ADMIN'
        )
    );

-- Politique pour supprimer un sinistre (admin seulement)
CREATE POLICY "Only admins can delete claims"
    ON claims FOR DELETE
    TO authenticated
    USING (
        building_id IN (
            SELECT rb.building_id
            FROM resident_building rb
            WHERE rb.resident_id = auth.uid()
            AND rb.role = 'ADMIN'
        )
    );

-- Politiques pour claim_affected_apartments
CREATE POLICY "Users can insert affected apartments when creating claim"
    ON claim_affected_apartments FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM claims c
            WHERE c.id = claim_id
            AND c.reporter_id = auth.uid()
        )
    );

CREATE POLICY "Users can view affected apartments of visible claims"
    ON claim_affected_apartments FOR SELECT
    TO authenticated
    USING (
        claim_id IN (
            SELECT id FROM claims
            WHERE reporter_id = auth.uid()
            OR apartment_id IN (
                SELECT rb.apartment_id
                FROM resident_building rb
                WHERE rb.resident_id = auth.uid()
            )
            OR id IN (
                SELECT caa2.claim_id
                FROM claim_affected_apartments caa2
                INNER JOIN resident_building rb ON rb.apartment_id = caa2.apartment_id
                WHERE rb.resident_id = auth.uid()
            )
            OR building_id IN (
                SELECT rb.building_id
                FROM resident_building rb
                WHERE rb.resident_id = auth.uid()
                AND rb.role = 'ADMIN'
            )
        )
    );

CREATE POLICY "Users can update affected apartments for their claims"
    ON claim_affected_apartments FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM claims c
            WHERE c.id = claim_id
            AND (
                c.reporter_id = auth.uid()
                OR c.building_id IN (
                    SELECT rb.building_id
                    FROM resident_building rb
                    WHERE rb.resident_id = auth.uid()
                    AND rb.role = 'ADMIN'
                )
            )
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM claims c
            WHERE c.id = claim_id
            AND (
                c.reporter_id = auth.uid()
                OR c.building_id IN (
                    SELECT rb.building_id
                    FROM resident_building rb
                    WHERE rb.resident_id = auth.uid()
                    AND rb.role = 'ADMIN'
                )
            )
        )
    );

CREATE POLICY "Users can delete affected apartments for their claims"
    ON claim_affected_apartments FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM claims c
            WHERE c.id = claim_id
            AND (
                c.reporter_id = auth.uid()
                OR c.building_id IN (
                    SELECT rb.building_id
                    FROM resident_building rb
                    WHERE rb.resident_id = auth.uid()
                    AND rb.role = 'ADMIN'
                )
            )
        )
    );

-- Politiques pour claim_photos
CREATE POLICY "Users can insert photos when creating claim"
    ON claim_photos FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM claims c
            WHERE c.id = claim_id
            AND c.reporter_id = auth.uid()
        )
    );

CREATE POLICY "Users can view photos of visible claims"
    ON claim_photos FOR SELECT
    TO authenticated
    USING (
        claim_id IN (
            SELECT id FROM claims
            WHERE reporter_id = auth.uid()
            OR apartment_id IN (
                SELECT rb.apartment_id
                FROM resident_building rb
                WHERE rb.resident_id = auth.uid()
            )
            OR id IN (
                SELECT caa.claim_id
                FROM claim_affected_apartments caa
                INNER JOIN resident_building rb ON rb.apartment_id = caa.apartment_id
                WHERE rb.resident_id = auth.uid()
            )
            OR building_id IN (
                SELECT rb.building_id
                FROM resident_building rb
                WHERE rb.resident_id = auth.uid()
                AND rb.role = 'ADMIN'
            )
        )
    );

CREATE POLICY "Users can update photos for their claims"
    ON claim_photos FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM claims c
            WHERE c.id = claim_id
            AND (
                c.reporter_id = auth.uid()
                OR c.building_id IN (
                    SELECT rb.building_id
                    FROM resident_building rb
                    WHERE rb.resident_id = auth.uid()
                    AND rb.role = 'ADMIN'
                )
            )
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM claims c
            WHERE c.id = claim_id
            AND (
                c.reporter_id = auth.uid()
                OR c.building_id IN (
                    SELECT rb.building_id
                    FROM resident_building rb
                    WHERE rb.resident_id = auth.uid()
                    AND rb.role = 'ADMIN'
                )
            )
        )
    );

CREATE POLICY "Users can delete photos for their claims"
    ON claim_photos FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM claims c
            WHERE c.id = claim_id
            AND (
                c.reporter_id = auth.uid()
                OR c.building_id IN (
                    SELECT rb.building_id
                    FROM resident_building rb
                    WHERE rb.resident_id = auth.uid()
                    AND rb.role = 'ADMIN'
                )
            )
        )
    );
