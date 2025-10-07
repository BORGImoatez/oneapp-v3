# Documentation : Système de dossiers partagés

## Vue d'ensemble

Le système de gestion des documents implémente une logique de partage granulaire :

- **Résidents** : Les dossiers créés sont **privés** par défaut (visibles uniquement par leur appartement)
- **Administrateurs** : Peuvent créer des dossiers **partagés** (visibles par tous les appartements de l'immeuble)

## Comportement détaillé

### 1. Création de dossiers

#### Résident (rôle: RESIDENT)
- Peut créer des dossiers **privés uniquement**
- Ces dossiers sont stockés dans `apartment_{id_appartement}/...`
- Seul l'appartement propriétaire peut voir et accéder à ces dossiers
- Si un résident essaie de créer un dossier partagé (`isShared: true`), il reçoit une erreur : **"Seuls les administrateurs peuvent créer des dossiers partagés"**

#### Admin/Syndic (rôle: ADMIN ou SYNDIC)
- Peut créer des dossiers **privés** (`isShared: false`)
- Peut créer des dossiers **partagés** (`isShared: true`)
- Les dossiers partagés sont visibles par **tous les appartements de l'immeuble**
- Les dossiers partagés sont toujours liés à l'appartement de l'admin qui les a créés

### 2. Affichage des dossiers

L'utilisateur voit :
- **Ses propres dossiers** (créés par son appartement)
- **Les dossiers partagés** (créés par un admin avec `isShared: true`)

SQL de filtrage :
```sql
SELECT f FROM Folder f
WHERE f.building.buildingId = :buildingId
AND f.parentFolder IS NULL
AND (f.isShared = true OR f.apartment.idApartment = :apartmentId)
```

### 3. Sous-dossiers

Les sous-dossiers suivent la même logique :
- Un sous-dossier dans un dossier partagé peut être privé ou partagé (selon le créateur)
- Un sous-dossier dans un dossier privé suit la visibilité du parent

### 4. Documents

Les documents héritent de la visibilité de leur dossier parent :
- Document dans un dossier **partagé** → visible par tous les appartements de l'immeuble
- Document dans un dossier **privé** → visible uniquement par l'appartement propriétaire

### 5. Opérations sécurisées

Toutes les opérations (lecture, téléchargement, suppression) vérifient :
1. L'utilisateur est dans l'immeuble sélectionné (`buildingId`)
2. Le dossier/document est soit partagé, soit appartient à l'appartement de l'utilisateur

## Architecture technique

### Base de données

**Table `folders`**
- `apartment_id` (nullable) : Appartement propriétaire
- `building_id` (NOT NULL) : Immeuble
- `is_shared` (BOOLEAN, default: false) : Dossier partagé ou non

**Table `documents`**
- Hérite de la visibilité du dossier parent via `folder.is_shared`

### Vérification des rôles

Le service utilise `SecurityContextUtil.getCurrentUserRole()` pour extraire le rôle du JWT :
- Rôles admin : `"ADMIN"`, `"SYNDIC"`
- Rôle résident : `"RESIDENT"`

### Endpoints API

**Création de dossier**
```http
POST /api/v1/documents/folders
Content-Type: application/json

{
  "name": "Documents Syndic",
  "parentFolderId": null,
  "description": "Dossier partagé pour tous",
  "isShared": true  // Seulement si admin
}
```

**Réponse**
```json
{
  "id": 123,
  "name": "Documents Syndic",
  "apartmentId": "APT001",
  "buildingId": "BUILD001",
  "isShared": true,
  "createdBy": "USER123",
  "createdAt": "2025-10-03T10:00:00Z"
}
```

## Scénarios d'utilisation

### Scénario 1 : Résident crée un dossier

1. Jean (RESIDENT) crée un dossier "Mes Documents"
2. Le dossier est automatiquement privé (`isShared: false`)
3. Seul Jean (et son appartement) peut le voir
4. Les autres résidents de l'immeuble ne voient pas ce dossier

### Scénario 2 : Admin crée un dossier partagé

1. Marie (ADMIN) crée un dossier "Assemblée Générale"
2. Elle coche l'option "Partager avec tout l'immeuble" (`isShared: true`)
3. Le dossier est visible par **tous les appartements** de l'immeuble
4. Tous les résidents peuvent voir et télécharger les documents
5. Le dossier reste lié à l'appartement de Marie pour la traçabilité

### Scénario 3 : Résident essaie de créer un dossier partagé

1. Pierre (RESIDENT) essaie de créer un dossier avec `isShared: true`
2. Le système rejette la requête
3. Erreur : "Seuls les administrateurs peuvent créer des dossiers partagés"

### Scénario 4 : Changement d'immeuble

1. Julie est dans l'immeuble A
2. Elle voit ses dossiers privés + les dossiers partagés de l'immeuble A
3. Elle change vers l'immeuble B
4. Elle voit maintenant ses dossiers privés de l'immeuble B + les dossiers partagés de l'immeuble B
5. Les dossiers de l'immeuble A disparaissent

## Migration

### Exécution de la migration SQL

```bash
psql -h <host> -U <user> -d <database> -f migration_shared_folders.sql
```

### Points importants

1. Tous les dossiers existants deviennent **privés** par défaut
2. Les admins doivent recréer les dossiers qui doivent être partagés
3. La colonne `is_shared` est indexée pour les performances

## Tests recommandés

### Tests fonctionnels

1. **Test Résident - Création privée**
   - Se connecter en tant que résident
   - Créer un dossier
   - Vérifier qu'il est privé par défaut
   - Vérifier que les autres résidents ne le voient pas

2. **Test Résident - Tentative de partage**
   - Se connecter en tant que résident
   - Essayer de créer un dossier avec `isShared: true`
   - Vérifier l'erreur

3. **Test Admin - Création partagée**
   - Se connecter en tant qu'admin
   - Créer un dossier partagé
   - Vérifier que tous les résidents le voient

4. **Test Admin - Création privée**
   - Se connecter en tant qu'admin
   - Créer un dossier privé (`isShared: false`)
   - Vérifier que seul l'admin le voit

5. **Test Changement d'immeuble**
   - Créer des dossiers dans l'immeuble A
   - Changer vers l'immeuble B
   - Vérifier que seuls les dossiers de B sont visibles

### Tests de sécurité

1. Vérifier qu'un résident ne peut pas accéder aux dossiers privés d'un autre appartement
2. Vérifier qu'un résident peut accéder aux dossiers partagés
3. Vérifier qu'on ne peut pas accéder aux dossiers d'un autre immeuble
4. Vérifier qu'on ne peut pas modifier `isShared` via une API non autorisée

## Avantages de cette approche

1. **Flexibilité** : Admins peuvent choisir ce qui est partagé
2. **Sécurité** : Les dossiers privés restent vraiment privés
3. **Traçabilité** : On sait qui a créé chaque dossier
4. **Simplicité** : Le comportement est clair et prévisible
5. **Performance** : Les requêtes sont optimisées avec des index appropriés

## Évolutions futures possibles

1. **Permissions granulaires** : Partager avec des appartements spécifiques
2. **Groupes** : Créer des groupes d'appartements
3. **Permissions en écriture** : Permettre à certains de modifier/supprimer
4. **Notifications** : Notifier quand un nouveau dossier partagé est créé
5. **Historique** : Tracer toutes les actions sur les dossiers partagés
