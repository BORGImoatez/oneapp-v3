# Module de Déclaration des Sinistres - Résumé d'Implémentation

## Vue d'ensemble

Module complet permettant aux résidents de déclarer des sinistres avec notifications push automatiques pour les administrateurs et les résidents des appartements affectés.

---

## Backend (Java Spring Boot)

### 1. Base de données (Migration V7)

**Tables créées:**

- **incidents**
  - Informations principales du sinistre
  - Statut, gravité, dates
  - Référence au bâtiment et appartement déclarant

- **incident_types**
  - Types de sinistres (choix multiples possibles)
  - 8 types disponibles: Incendie, Vol, Dégâts des eaux, etc.

- **incident_affected_apartments**
  - Liste des appartements touchés par le sinistre
  - Notifications automatiques aux résidents concernés

- **incident_images**
  - Photos du sinistre (multiples possibles)
  - Stockage des URLs d'images

### 2. Modèles Java

**Enums:**
- `IncidentType` - 8 types de sinistres
- `IncidentStatus` - PENDING, IN_PROGRESS, RESOLVED, CLOSED
- `IncidentSeverity` - LOW, MEDIUM, HIGH, CRITICAL

**Entités:**
- `Incident` - Entité principale
- `IncidentTypeEntity` - Relation many-to-many pour types
- `IncidentAffectedApartment` - Appartements affectés
- `IncidentImage` - Photos du sinistre

### 3. API Endpoints

**POST /api/v1/incidents**
- Créer un nouveau sinistre
- Corps de requête: `CreateIncidentRequest`
- Champs requis:
  - `apartmentId` - ID de l'appartement déclarant
  - `types[]` - Liste des types de sinistres
  - `cause` - Cause du sinistre
  - `description` - Description des dégâts
  - `insuranceCompany` - Compagnie d'assurance (optionnel)
  - `insurancePolicyNumber` - N° de police (optionnel)
  - `affectedApartmentIds[]` - Appartements touchés (optionnel)

**POST /api/v1/incidents/{id}/images**
- Ajouter des images à un sinistre
- Upload multiple d'images
- Seul le déclarant peut ajouter des images

**PUT /api/v1/incidents/{id}/status** (Admin uniquement)
- Mettre à jour le statut et/ou la gravité
- Corps: `{ "status": "IN_PROGRESS", "severity": "HIGH" }`

**GET /api/v1/incidents/my**
- Récupérer mes sinistres (déclarés + appartements affectés)

**GET /api/v1/incidents/building** (Admin uniquement)
- Tous les sinistres du bâtiment

**GET /api/v1/incidents/{id}**
- Détails d'un sinistre spécifique

### 4. Notifications Push Automatiques

**Lors de la création d'un sinistre:**
- ✅ Notification envoyée à tous les admins du bâtiment
- ✅ Notification envoyée aux résidents de chaque appartement coché comme "touché"
- Message: "Nouveau sinistre déclaré dans l'appartement X par Y"

**Lors de la mise à jour du statut:**
- ✅ Notification envoyée au déclarant
- Message: "Le statut du sinistre a été mis à jour: [STATUS]"

---

## Frontend (Flutter)

### 1. Modèles Dart

**`IncidentModel`** (`lib/models/incident_model.dart`)
- Toutes les propriétés du sinistre
- Méthodes de conversion JSON
- Méthodes utilitaires pour les labels français

**`AffectedApartmentModel`**
- Informations d'un appartement affecté

### 2. Service API

**`IncidentService`** (`lib/services/incident_service.dart`)
- `createIncident()` - Créer un sinistre
- `addIncidentImages()` - Ajouter des images
- `updateIncidentStatus()` - Mettre à jour (admin)
- `getBuildingIncidents()` - Liste complète (admin)
- `getMyIncidents()` - Mes sinistres
- `getIncidentById()` - Détail d'un sinistre

### 3. Provider

**`IncidentProvider`** (`lib/providers/incident_provider.dart`)
- Gestion de l'état des sinistres
- Cache des données par bâtiment
- Loading states et gestion d'erreurs

### 4. Écrans

#### **IncidentsScreen** (`lib/screens/incidents/incidents_screen.dart`)
- Liste des sinistres avec 2 onglets (pour admin):
  - "Mes sinistres" - Déclarés ou appartements affectés
  - "Tous les sinistres" - Vue complète du bâtiment
- Cards avec icônes selon le type
- Badges de statut colorés
- Affichage du nombre d'appartements affectés
- Pull-to-refresh

#### **CreateIncidentScreen** (`lib/screens/incidents/create_incident_screen.dart`)
- ✅ **Sélection multiple des types** (checkboxes avec chips)
  - Incendie, Vol, Dégâts des eaux, etc.
- ✅ **Champ cause** (requis, multi-ligne)
- ✅ **Champ description** (requis, multi-ligne)
- ✅ **Compagnie d'assurance** (optionnel)
- ✅ **N° de police d'assurance** (optionnel)
- ✅ **Sélection multiple des appartements touchés** (liste avec checkboxes)
  - Affiche tous les appartements du bâtiment
  - Indique l'étage de chaque appartement
- ✅ **Ajout multiple d'images** (optionnel)
  - Grille de prévisualisation
  - Possibilité de supprimer des images
- Validation du formulaire
- Loading state pendant l'upload

#### **IncidentDetailScreen** (`lib/screens/incidents/incident_detail_screen.dart`)
- Vue complète d'un sinistre
- Sections:
  - Statut et gravité avec icônes colorées
  - Informations générales (appartement, déclarant)
  - Types de sinistre (chips)
  - Cause et description
  - Assurance (si renseignée)
  - Appartements affectés (liste)
  - Photos (grille, zoom en plein écran)
- Bouton "Modifier le statut" pour admin
- Dialog de mise à jour avec dropdowns

### 5. Intégration

**Dans `main.dart`:**
```dart
ChangeNotifierProvider(create: (_) => IncidentProvider())
```

**Dans `home_screen.dart`:**
- Carte "Sinistres" dans l'accès rapide
- Navigation vers `IncidentsScreen`

---

## Fonctionnalités Clés

### ✅ Tous les critères demandés

1. **Type de sinistre** - Choix multiples avec 8 options
2. **Cause du sinistre** - Champ texte requis
3. **Description des dégâts** - Champ texte requis
4. **Compagnie d'assurance** - Champ texte optionnel
5. **N° de police d'assurance** - Champ texte optionnel
6. **Appartements touchés** - Liste avec choix multiples
7. **Images** - Upload multiple optionnel

### ✅ Notifications Push

- Admin reçoit notification à chaque nouveau sinistre
- Résidents des appartements cochés reçoivent notification
- Déclarant reçoit notification lors des mises à jour

### ✅ Permissions

- Tout résident peut déclarer un sinistre
- Tout résident peut voir ses propres sinistres
- Résidents des appartements affectés peuvent consulter le sinistre
- Admin peut voir tous les sinistres
- Admin peut modifier le statut et la gravité

---

## Prochaines Étapes pour Tester

1. **Appliquer la migration:**
   - La migration V7 sera automatiquement appliquée au démarrage du backend

2. **Compiler le backend:**
   ```bash
   ./mvnw clean install
   ```

3. **Compiler le frontend:**
   ```bash
   flutter pub get
   flutter build apk --release  # ou flutter run pour tester
   ```

4. **Tester le flux:**
   - Se connecter comme résident
   - Aller sur "Sinistres" depuis l'accueil
   - Cliquer sur "+" pour déclarer un sinistre
   - Remplir le formulaire avec plusieurs types
   - Cocher des appartements affectés
   - Ajouter des photos
   - Soumettre
   - Vérifier les notifications push

---

## Notes Techniques

- Les images sont uploadées via le service existant `FileService`
- Les notifications utilisent le service existant `NotificationService` + FCM
- Le contexte du bâtiment est géré automatiquement
- Toutes les données sont filtrées par bâtiment pour la multi-résidence
- Les permissions RLS sont gérées côté backend via JWT

---

## Fichiers Créés/Modifiés

**Backend:**
- `V7__Create_incidents_table.sql` - Migration
- `Incident.java`, `IncidentTypeEntity.java`, etc. - Modèles
- `IncidentType.java`, `IncidentStatus.java`, `IncidentSeverity.java` - Enums
- `IncidentDto.java`, `CreateIncidentRequest.java`, etc. - DTOs
- `IncidentRepository.java` et repositories associés
- `IncidentService.java` - Logique métier + notifications
- `IncidentController.java` - Endpoints REST

**Frontend:**
- `incident_model.dart` - Modèle Flutter
- `incident_service.dart` - Service API
- `incident_provider.dart` - Provider
- `incidents_screen.dart` - Liste
- `create_incident_screen.dart` - Formulaire
- `incident_detail_screen.dart` - Détail
- `main.dart` - Ajout du provider
- `home_screen.dart` - Navigation
- `api_service.dart` - Ajout de `uploadMultipleFiles()`

---

Module complet et prêt à l'emploi! 🎉
