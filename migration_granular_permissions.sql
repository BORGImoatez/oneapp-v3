/*
  # Migration: Système de Permissions Granulaires pour les Dossiers

  ## Objectif
  Implémenter un système de partage granulaire permettant aux administrateurs et résidents
  de contrôler finement l'accès aux dossiers et fichiers.

  ## Nouvelles Tables

  ### folder_permissions
  Table pour gérer les permissions spécifiques par appartement ou résident
  - `id` (bigserial, primary key)
  - `folder_id` (bigint, foreign key vers folders)
  - `apartment_id` (varchar, foreign key vers apartments) - Optionnel
  - `resident_id` (varchar, foreign key vers residents) - Optionnel
  - `can_read` (boolean, default true) - Permission de lecture
  - `can_upload` (boolean, default false) - Permission d'upload
  - `created_at` (timestamp)

  ## Modifications Tables Existantes

  ### folders
  Ajout de:
  - `share_type` (varchar) - Type de partage: PRIVATE, ALL_APARTMENTS, SPECIFIC_APARTMENTS

  ## Fonctionnalités

  1. **Admin sans appartement**:
     - Peut créer des dossiers d'immeuble
     - Peut choisir ALL_APARTMENTS (tous) ou SPECIFIC_APARTMENTS (sélection)
     - Pour SPECIFIC_APARTMENTS, peut spécifier les appartements/résidents autorisés

  2. **Admin/Résident avec appartement**:
     - Peut créer des dossiers PRIVATE (privés à son appartement)
     - Peut créer des dossiers ALL_APARTMENTS (partagés avec tous)
     - Peut créer des dossiers SPECIFIC_APARTMENTS (sélection d'appartements/résidents)

  3. **Permissions**:
     - `can_read`: Permet de voir et télécharger les fichiers
     - `can_upload`: Permet d'uploader des fichiers dans le dossier

  ## Sécurité
  - Les dossiers PRIVATE ne sont visibles que par le créateur et son appartement
  - Les dossiers ALL_APARTMENTS sont visibles par tous les appartements de l'immeuble
  - Les dossiers SPECIFIC_APARTMENTS sont visibles uniquement par les appartements/résidents autorisés
  - Le créateur a toujours accès complet à ses dossiers
*/

-- Ajout de la colonne share_type à la table folders
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'folders' AND column_name = 'share_type'
  ) THEN
    ALTER TABLE folders ADD COLUMN share_type VARCHAR(50) NOT NULL DEFAULT 'PRIVATE';

    -- Mettre à jour les dossiers existants selon leur statut is_shared
    UPDATE folders SET share_type = 'ALL_APARTMENTS' WHERE is_shared = true;
    UPDATE folders SET share_type = 'PRIVATE' WHERE is_shared = false OR is_shared IS NULL;
  END IF;
END $$;

-- Création de la table folder_permissions
CREATE TABLE IF NOT EXISTS folder_permissions (
  id BIGSERIAL PRIMARY KEY,
  folder_id BIGINT NOT NULL,
  apartment_id VARCHAR(255),
  resident_id VARCHAR(255),
  can_read BOOLEAN NOT NULL DEFAULT true,
  can_upload BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_folder_permission_folder FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE,
  CONSTRAINT fk_folder_permission_apartment FOREIGN KEY (apartment_id) REFERENCES apartments(id_apartment) ON DELETE CASCADE,
  CONSTRAINT fk_folder_permission_resident FOREIGN KEY (resident_id) REFERENCES residents(id_users) ON DELETE CASCADE,

  -- Au moins un de apartment_id ou resident_id doit être défini
  CONSTRAINT check_apartment_or_resident CHECK (apartment_id IS NOT NULL OR resident_id IS NOT NULL)
);

-- Index pour améliorer les performances des requêtes de permissions
CREATE INDEX IF NOT EXISTS idx_folder_permissions_folder_id ON folder_permissions(folder_id);
CREATE INDEX IF NOT EXISTS idx_folder_permissions_apartment_id ON folder_permissions(apartment_id);
CREATE INDEX IF NOT EXISTS idx_folder_permissions_resident_id ON folder_permissions(resident_id);
CREATE INDEX IF NOT EXISTS idx_folders_share_type ON folders(share_type);
CREATE INDEX IF NOT EXISTS idx_folders_building_share_type ON folders(building_id, share_type);

-- Permettre aux apartments d'être NULL pour les dossiers d'immeuble (admin sans appartement)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'folders' AND column_name = 'apartment_id'
    AND is_nullable = 'NO'
  ) THEN
    ALTER TABLE folders ALTER COLUMN apartment_id DROP NOT NULL;
  END IF;
END $$;

-- Commentaires pour documentation
COMMENT ON TABLE folder_permissions IS 'Gère les permissions granulaires pour les dossiers partagés avec des appartements ou résidents spécifiques';
COMMENT ON COLUMN folder_permissions.can_read IS 'Permission de lecture et téléchargement des fichiers';
COMMENT ON COLUMN folder_permissions.can_upload IS 'Permission d''upload de fichiers dans le dossier';
COMMENT ON COLUMN folders.share_type IS 'Type de partage: PRIVATE (privé), ALL_APARTMENTS (tous les appartements), SPECIFIC_APARTMENTS (appartements spécifiques)';
