# Migration: Filtrage des documents par immeuble (building)

## Résumé
Cette migration modifie le système de gestion des documents pour filtrer par **immeuble (building)** au lieu de par **appartement (apartment)**. Les utilisateurs ne verront désormais que les dossiers et fichiers de l'immeuble auquel ils sont connectés.

## Modifications effectuées

### 1. Modèles de données (Entities)

#### Folder.java
- Ajout de la relation `building` (ManyToOne)
- `apartment` devient optionnel (nullable)
- `building` devient obligatoire

#### Document.java
- Ajout de la relation `building` (ManyToOne)
- `apartment` devient optionnel (nullable)
- `building` devient obligatoire

### 2. Repositories

#### FolderRepository.java
Ajout des méthodes :
- `findByBuildingIdAndParentFolderIsNull(String buildingId)`
- `findByIdAndBuildingId(Long id, String buildingId)`
- `findByBuildingIdAndParentFolderId(String buildingId, Long parentId)`
- `existsByNameAndParentFolderIdAndBuildingId(String name, Long parentFolderId, String buildingId)`
- `existsByNameAndParentFolderIsNullAndBuildingId(String name, String buildingId)`

#### DocumentRepository.java
Ajout des méthodes :
- `findByBuildingId(String buildingId)`
- `findByBuildingId(String buildingId, Pageable pageable)`
- `findByIdAndBuildingId(Long id, String buildingId)`
- `searchDocuments(String buildingId, String search)`

### 3. Services

#### DocumentService.java
Modifications principales :
- Utilisation de `SecurityContextUtil.getCurrentBuildingId()` au lieu de récupérer l'appartement du résident
- Tous les filtres utilisent maintenant `buildingId` au lieu de `apartmentId`
- Le dossier racine est maintenant `building_{buildingId}` au lieu de `apartment_{apartmentId}`
- Les logs mentionnent "immeuble" au lieu de "appartement"

Méthodes modifiées :
- `createFolder()` - filtre par buildingId
- `getRootFolders()` - filtre par buildingId
- `getSubFolders()` - filtre par buildingId
- `getFolderDocuments()` - filtre par buildingId
- `uploadDocument()` - associe au buildingId
- `deleteFolder()` - vérifie le buildingId
- `deleteDocument()` - vérifie le buildingId
- `downloadDocument()` - vérifie le buildingId
- `searchDocuments()` - filtre par buildingId
- `ensureBuildingRootFolderExists()` - nouvelle méthode pour créer le dossier racine de l'immeuble

### 4. DTOs

#### FolderDto.java
- Ajout du champ `buildingId`

#### DocumentDto.java
- Ajout du champ `buildingId`

## Migration de la base de données

### Fichier de migration
Un script SQL a été créé : `migration_building_context_documents.sql`

### Étapes de la migration
1. Ajouter la colonne `building_id` aux tables `folders` et `documents`
2. Rendre `apartment_id` nullable dans les deux tables
3. Populer `building_id` à partir de la relation `apartment.building_id`
4. Ajouter les contraintes de clé étrangère
5. Rendre `building_id` NOT NULL
6. Créer les index pour optimiser les performances

### Exécution de la migration
```bash
psql -h <host> -U <user> -d <database> -f migration_building_context_documents.sql
```

## Impact sur le système

### Avantages
1. **Meilleure isolation** : Les documents sont maintenant isolés par immeuble
2. **Conformité** : Correspond au modèle de sélection d'immeuble (building selection)
3. **Performance** : Les requêtes sont plus efficaces car elles filtrent au niveau de l'immeuble
4. **Sécurité** : Les utilisateurs ne peuvent accéder qu'aux documents de leur immeuble sélectionné

### Points d'attention
1. Les dossiers et documents existants doivent avoir un `building_id` valide après la migration
2. Le token JWT doit contenir le `buildingId` (déjà implémenté dans `SecurityContextUtil`)
3. Les dossiers physiques sont maintenant organisés par immeuble : `building_{id}/...`

## Tests recommandés

1. Vérifier que les utilisateurs ne voient que les documents de leur immeuble
2. Tester la création de dossiers dans plusieurs immeubles
3. Vérifier l'upload de documents dans différents immeubles
4. Tester la recherche de documents (doit filtrer par immeuble)
5. Vérifier les téléchargements de documents (doit vérifier le buildingId)
6. Tester le changement d'immeuble et vérifier que les documents changent

## Compatibilité

- Les anciennes méthodes filtrées par `apartment_id` sont conservées pour compatibilité
- La migration SQL est conçue pour être idempotente (peut être exécutée plusieurs fois)
