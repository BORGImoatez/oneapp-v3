# Documentation: Système de Permissions Granulaires

## Vue d'ensemble

Le système de permissions granulaires permet aux administrateurs et résidents de contrôler finement l'accès aux dossiers et fichiers dans l'application.

## Types d'utilisateurs

### 1. Admin sans appartement
Un administrateur qui n'est pas rattaché à un appartement spécifique dans un immeuble.

**Capacités:**
- Créer des dossiers d'immeuble (stockés sous `building_<buildingId>`)
- Choisir le type de partage:
  - `ALL_APARTMENTS`: Partagé avec tous les appartements de l'immeuble
  - `SPECIFIC_APARTMENTS`: Partagé avec des appartements ou résidents spécifiques

### 2. Admin/Résident avec appartement
Un administrateur ou un résident qui est rattaché à un appartement.

**Capacités:**
- Créer des dossiers privés (`PRIVATE`)
- Créer des dossiers partagés avec tous (`ALL_APARTMENTS`) - **Uniquement pour les admins**
- Créer des dossiers partagés spécifiquement (`SPECIFIC_APARTMENTS`) - **Uniquement pour les admins**

### 3. Résident sans privilèges admin
Un résident ordinaire.

**Capacités:**
- Créer uniquement des dossiers privés (`PRIVATE`)
- Accès uniquement aux dossiers privés de son appartement et aux dossiers partagés avec lui

## Types de partage

### PRIVATE
- Le dossier est visible uniquement par:
  - Le créateur du dossier
  - Les résidents du même appartement que le créateur
- Permissions automatiques: Lecture + Upload

### ALL_APARTMENTS
- Le dossier est visible par tous les appartements de l'immeuble
- Tous les résidents ont accès en lecture et en upload
- **Réservé aux administrateurs**

### SPECIFIC_APARTMENTS
- Le dossier est visible uniquement par:
  - Le créateur du dossier
  - Les appartements spécifiquement sélectionnés
  - Les résidents spécifiquement sélectionnés
- Permissions configurables par sélection:
  - `canRead`: Permission de lecture et téléchargement
  - `canUpload`: Permission d'upload de fichiers

## Structure de la base de données

### Table `folders`
```sql
- id: BIGSERIAL PRIMARY KEY
- name: VARCHAR NOT NULL
- folder_path: VARCHAR NOT NULL
- parent_folder_id: BIGINT (FK vers folders)
- apartment_id: VARCHAR (FK vers apartments) - Nullable pour admins sans appartement
- building_id: VARCHAR NOT NULL (FK vers buildings)
- created_by: VARCHAR NOT NULL
- is_shared: BOOLEAN DEFAULT false
- share_type: VARCHAR DEFAULT 'PRIVATE' (PRIVATE, ALL_APARTMENTS, SPECIFIC_APARTMENTS)
- created_at: TIMESTAMP
```

### Table `folder_permissions`
```sql
- id: BIGSERIAL PRIMARY KEY
- folder_id: BIGINT NOT NULL (FK vers folders)
- apartment_id: VARCHAR (FK vers apartments) - Optionnel
- resident_id: VARCHAR (FK vers residents) - Optionnel
- can_read: BOOLEAN DEFAULT true
- can_upload: BOOLEAN DEFAULT false
- created_at: TIMESTAMP
```

**Contrainte:** Au moins un de `apartment_id` ou `resident_id` doit être défini.

## API - Création de dossier

### Endpoint
```
POST /api/v1/documents/folders
```

### Request Body

#### Exemple 1: Dossier privé (résident)
```json
{
  "name": "Mes documents",
  "parentFolderId": null,
  "shareType": "PRIVATE"
}
```

#### Exemple 2: Dossier partagé avec tous (admin)
```json
{
  "name": "Documents de syndic",
  "parentFolderId": null,
  "shareType": "ALL_APARTMENTS"
}
```

#### Exemple 3: Dossier partagé avec des appartements spécifiques (admin)
```json
{
  "name": "Documents confidentiels",
  "parentFolderId": null,
  "shareType": "SPECIFIC_APARTMENTS",
  "sharedApartmentIds": ["apt-123", "apt-456"],
  "allowUpload": true
}
```

#### Exemple 4: Dossier partagé avec des résidents spécifiques (admin)
```json
{
  "name": "Documents partagés",
  "parentFolderId": null,
  "shareType": "SPECIFIC_APARTMENTS",
  "sharedResidentIds": ["user-789", "user-101"],
  "allowUpload": false
}
```

#### Exemple 5: Combinaison appartements + résidents (admin)
```json
{
  "name": "Documents mixtes",
  "parentFolderId": null,
  "shareType": "SPECIFIC_APARTMENTS",
  "sharedApartmentIds": ["apt-123"],
  "sharedResidentIds": ["user-789"],
  "allowUpload": true
}
```

## Logique de vérification des permissions

### Lecture (canRead)
Un utilisateur peut lire un dossier si:
1. Il est le créateur du dossier, OU
2. Le dossier est de type `ALL_APARTMENTS`, OU
3. Le dossier est `PRIVATE` et l'utilisateur appartient au même appartement, OU
4. Le dossier est `SPECIFIC_APARTMENTS` et:
   - L'utilisateur est dans la liste des résidents autorisés, OU
   - L'appartement de l'utilisateur est dans la liste des appartements autorisés

### Upload (canUpload)
Un utilisateur peut uploader dans un dossier si:
1. Il est le créateur du dossier, OU
2. Le dossier est de type `ALL_APARTMENTS`, OU
3. Le dossier est `PRIVATE` et l'utilisateur appartient au même appartement, OU
4. Le dossier est `SPECIFIC_APARTMENTS` ET la permission a `canUpload=true` ET:
   - L'utilisateur est dans la liste des résidents autorisés, OU
   - L'appartement de l'utilisateur est dans la liste des appartements autorisés

## Modèles Flutter

### FolderModel
```dart
class FolderModel {
  final int id;
  final String name;
  final String folderPath;
  final int? parentFolderId;
  final String? apartmentId;
  final String? buildingId;
  final String createdBy;
  final bool isShared;
  final String shareType;  // 'PRIVATE', 'ALL_APARTMENTS', 'SPECIFIC_APARTMENTS'
  final DateTime createdAt;
  final int subFolderCount;
  final int documentCount;
  final List<FolderPermissionModel> permissions;
  final bool canRead;
  final bool canUpload;
}
```

### FolderPermissionModel
```dart
class FolderPermissionModel {
  final int id;
  final String? apartmentId;
  final String? residentId;
  final bool canRead;
  final bool canUpload;
}
```

## Flux de travail

### Scénario 1: Résident crée un dossier privé
1. Résident se connecte et sélectionne son immeuble
2. Va dans la section "Fichiers"
3. Clique sur "Nouveau dossier"
4. Entre le nom du dossier
5. Le type est automatiquement `PRIVATE` (pas d'option de partage visible)
6. Le dossier est créé et visible uniquement par les résidents de son appartement

### Scénario 2: Admin crée un dossier pour tous
1. Admin se connecte et sélectionne l'immeuble
2. Va dans la section "Fichiers"
3. Clique sur "Nouveau dossier"
4. Entre le nom du dossier
5. Sélectionne "Partager avec tous les appartements"
6. Le dossier est créé avec `shareType=ALL_APARTMENTS`
7. Tous les résidents de l'immeuble peuvent voir et uploader dans ce dossier

### Scénario 3: Admin crée un dossier pour des appartements spécifiques
1. Admin se connecte et sélectionne l'immeuble
2. Va dans la section "Fichiers"
3. Clique sur "Nouveau dossier"
4. Entre le nom du dossier
5. Sélectionne "Partager avec des appartements spécifiques"
6. Sélectionne les appartements (ex: Apt 101, Apt 205)
7. Choisit les permissions:
   - ✓ Lecture (toujours activé)
   - ✓ Upload (optionnel)
8. Le dossier est créé avec `shareType=SPECIFIC_APARTMENTS`
9. Seuls les appartements sélectionnés peuvent voir le dossier
10. Si "Upload" est coché, ils peuvent aussi uploader des fichiers

### Scénario 4: Admin sans appartement crée un dossier d'immeuble
1. Admin sans appartement se connecte
2. Sélectionne l'immeuble
3. Va dans la section "Fichiers"
4. Clique sur "Nouveau dossier"
5. Entre le nom du dossier
6. Choisit entre:
   - "Partager avec tous" → `ALL_APARTMENTS`
   - "Partager avec sélection" → `SPECIFIC_APARTMENTS` + sélection
7. Le dossier est créé sous `building_<buildingId>/nom_dossier`
8. Les permissions s'appliquent selon le choix

## Migration

Pour migrer vers ce système:

1. Exécuter le script SQL `migration_granular_permissions.sql`
2. Les dossiers existants seront automatiquement migrés:
   - `is_shared=true` → `share_type=ALL_APARTMENTS`
   - `is_shared=false` → `share_type=PRIVATE`
3. Redémarrer le backend
4. Mettre à jour l'application Flutter avec les nouveaux modèles

## Sécurité

### Principes
1. **Principe du moindre privilège**: Par défaut, un dossier est `PRIVATE`
2. **Créateur tout-puissant**: Le créateur a toujours accès complet à ses dossiers
3. **Admin contrôle**: Seuls les admins peuvent créer des dossiers partagés
4. **Vérification systématique**: Chaque opération vérifie les permissions

### Vérifications
- Création: Vérification du rôle (admin/resident) et des permissions
- Lecture: Vérification via `checkFolderReadPermission()`
- Upload: Vérification via `checkFolderUploadPermission()`
- Suppression: Seul le créateur ou un admin peut supprimer

## Notes importantes

1. **Compatibilité ascendante**: Le champ `isShared` est conservé pour compatibilité
2. **Performance**: Index créés sur `share_type`, `building_id`, `apartment_id`, `resident_id`
3. **Cascade**: La suppression d'un dossier supprime automatiquement ses permissions
4. **Changement de building**: Le système gère correctement les utilisateurs avec plusieurs appartements dans différents immeubles via `ResidentBuilding`
