# Mise à jour du système de partage de dossiers

## Résumé des modifications

Les modifications suivantes ont été apportées au système de partage de dossiers pour répondre aux exigences suivantes :

### Exigences

1. **Trois options de partage uniquement** :
   - Privé (visible uniquement par le créateur)
   - Tous les résidents de l'immeuble (lecture seule pour tous)
   - Résidents spécifiques (sélection manuelle avec permissions personnalisées)

2. **Affichage des résidents** :
   - Liste complète avec nom, prénom, numéro d'appartement et étage
   - Filtres disponibles : par étage et par nom/prénom

3. **Restrictions** :
   - Seul le créateur du dossier peut modifier les permissions de partage

## Modifications apportées

### 1. Backend (Java)

#### `BuildingMembersDto.java`
- Ajout du champ `floor` au DTO `ResidentSummaryDto`
- Ce champ contient l'étage de l'appartement du résident

#### `DocumentService.java`
- Mise à jour de la méthode `getBuildingMembers()` pour inclure le numéro d'étage dans la réponse
- Le champ `floor` est extrait de `rb.getApartment().getApartmentFloor()`

### 2. Frontend (Flutter)

#### `building_members_model.dart`
- Ajout du champ `floor` au modèle `ResidentSummary`
- Ajout d'une propriété calculée `displayInfo` qui retourne une chaîne formatée :
  - Format : "Appt [numéro] - Étage [étage]"
  - Exemple : "Appt 302 - Étage 3"

#### `folder_permissions_screen.dart`
- Amélioration des descriptions des types de partage :
  - **Privé** : "Visible uniquement par le créateur"
  - **Tous les résidents de l'immeuble** : "Tous les résidents peuvent voir (lecture seule)"
  - **Résidents spécifiques** : "Sélectionner les résidents avec permissions personnalisées"

- Les filtres existants restent inchangés :
  - Recherche par nom/prénom (zone de texte)
  - Filtre par étage (liste déroulante)

### 3. Sécurité

Le système garantit que :
- Seul le créateur du dossier peut accéder à l'écran de gestion des permissions (vérifié dans `files_screen.dart` ligne 440)
- Le backend vérifie également que seul le créateur peut modifier les permissions (vérifié dans `DocumentService.java` ligne 203-205)

## Fonctionnement

### Interface utilisateur

1. **Écran de liste des dossiers** :
   - Les dossiers affichent un badge indiquant le type de partage
   - Seul le créateur voit l'option "Gérer les permissions" dans le menu contextuel

2. **Écran de gestion des permissions** :
   - Sélection du type de partage (3 options)
   - Si "Résidents spécifiques" est sélectionné :
     - Zone de recherche par nom/prénom
     - Filtre par étage
     - Liste complète des résidents avec cases à cocher
     - Informations affichées : Nom complet + Appt [numéro] - Étage [étage]
     - Option pour autoriser l'upload de fichiers

### API Backend

- **GET** `/api/v1/documents/building-members` : Retourne la liste des résidents avec leurs informations (incluant l'étage)
- **PUT** `/api/v1/folders/{folderId}/permissions` : Met à jour les permissions d'un dossier

## Exemple d'affichage

```
Résidents spécifiques

[Filtres]
Rechercher: [Zone de texte]
Étage: [Tous les étages ▼]

Résidents (2 sélectionnés)
☑ Jean Dupont
  Appt 302 - Étage 3

☐ Marie Martin
  Appt 405 - Étage 4

☑ Pierre Durand
  Appt 301 - Étage 3
```

## Tests recommandés

1. Vérifier que seul le créateur du dossier peut accéder aux permissions
2. Tester les filtres (par étage et par nom)
3. Vérifier que les informations des résidents s'affichent correctement
4. Tester les trois types de partage
5. Vérifier que les permissions sont correctement enregistrées
