/*
  # Add Unique Constraint to Channel Members

  ## Description
  Ajoute une contrainte unique sur la combinaison (channel_id, user_id) dans la table channel_members
  pour éviter les doublons. Nettoie également les doublons existants en conservant le plus récent.

  ## 1. Modifications
    - Suppression des doublons existants (conservation du membre le plus récent)
    - Ajout d'une contrainte unique sur (channel_id, user_id, is_active)

  ## 2. Sécurité
    - Pas de changement de sécurité
    - Les données existantes sont nettoyées avant l'ajout de la contrainte
*/

-- Supprimer les doublons en gardant le plus récent (ID le plus élevé) pour chaque combinaison (channel_id, user_id)
DELETE FROM channel_members
WHERE id NOT IN (
    SELECT MAX(id)
    FROM channel_members
    GROUP BY channel_id, user_id
);

-- Ajouter une contrainte unique sur (channel_id, user_id)
-- Cela empêchera les doublons à l'avenir
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'uk_channel_member_user'
  ) THEN
    ALTER TABLE channel_members
    ADD CONSTRAINT uk_channel_member_user
    UNIQUE (channel_id, user_id);
  END IF;
END $$;

-- Créer un index pour améliorer les performances des recherches
CREATE INDEX IF NOT EXISTS idx_channel_members_user_id ON channel_members(user_id);
CREATE INDEX IF NOT EXISTS idx_channel_members_is_active ON channel_members(is_active);
