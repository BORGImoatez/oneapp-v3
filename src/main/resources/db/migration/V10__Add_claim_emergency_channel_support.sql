/*
  # Add Emergency Channel Support for Claims

  ## Description
  Ce fichier ajoute le support des canaux d'urgence pour les sinistres.
  Lorsqu'un sinistre est déclaré, un canal d'urgence et un dossier partagé sont automatiquement créés.

  ## 1. Modifications des Tables
    - Ajout de `emergency_channel_id` à `claims` pour lier le sinistre à son canal d'urgence
    - Ajout de `emergency_folder_id` à `claims` pour lier le sinistre à son dossier partagé
    - Ajout de `is_closed` à `channels` pour marquer les canaux d'urgence comme fermés
    - Ajout de `claim_id` à `folders` pour lier les dossiers de sinistres aux sinistres

  ## 2. Fonctionnalités
    - Canal d'urgence créé automatiquement lors de la déclaration d'un sinistre
    - Membres du canal: admin immeuble, déclarant, résidents des appartements affectés
    - Dossier partagé créé pour stocker tous les documents liés au sinistre
    - Documents envoyés dans le canal sont automatiquement stockés dans le dossier
    - Admin peut clôturer le sinistre, ce qui ferme le canal (lecture seule)

  ## 3. Sécurité
    - Les politiques RLS existantes gèrent les nouveaux champs
    - Pas de changement de sécurité nécessaire
*/

-- Ajouter les colonnes pour lier les sinistres aux canaux d'urgence et dossiers
ALTER TABLE claims ADD COLUMN IF NOT EXISTS emergency_channel_id BIGINT;
ALTER TABLE claims ADD COLUMN IF NOT EXISTS emergency_folder_id BIGINT;

-- Ajouter le flag is_closed aux canaux
ALTER TABLE channels ADD COLUMN IF NOT EXISTS is_closed BOOLEAN DEFAULT FALSE;

-- Ajouter claim_id aux dossiers pour lier les dossiers de sinistres
ALTER TABLE folders ADD COLUMN IF NOT EXISTS claim_id BIGINT;

-- Ajouter les contraintes de clé étrangère
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_claims_emergency_channel'
  ) THEN
    ALTER TABLE claims ADD CONSTRAINT fk_claims_emergency_channel
      FOREIGN KEY (emergency_channel_id) REFERENCES channels(id) ON DELETE SET NULL;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_claims_emergency_folder'
  ) THEN
    ALTER TABLE claims ADD CONSTRAINT fk_claims_emergency_folder
      FOREIGN KEY (emergency_folder_id) REFERENCES folders(id) ON DELETE SET NULL;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_folders_claim'
  ) THEN
    ALTER TABLE folders ADD CONSTRAINT fk_folders_claim
      FOREIGN KEY (claim_id) REFERENCES claims(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Créer les index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_claims_emergency_channel ON claims(emergency_channel_id);
CREATE INDEX IF NOT EXISTS idx_claims_emergency_folder ON claims(emergency_folder_id);
CREATE INDEX IF NOT EXISTS idx_channels_is_closed ON channels(is_closed);
CREATE INDEX IF NOT EXISTS idx_folders_claim_id ON folders(claim_id);
