# Corrections du filtrage par immeuble (Building Context)

## Problème identifié
Les utilisateurs voyaient les données (channels, messages, votes) de TOUS les immeubles au lieu de voir uniquement les données de l'immeuble sélectionné.

## Corrections apportées

### 1. JwtAuthenticationFilter
**Fichier:** `src/main/java/be/delomid/oneapp/mschat/mschat/config/JwtAuthenticationFilter.java`

**Modification:** Le filtre extrait maintenant le `buildingId`, `userId` et `role` du JWT et les stocke dans les détails de l'authentification.

```java
// Extract building context from JWT
String buildingId = jwtConfig.extractBuildingId(jwt);
String userId = jwtConfig.extractUserId(jwt);
String role = jwtConfig.extractRole(jwt);

// Store building context in authentication details
Map<String, Object> details = new HashMap<>();
details.put("buildingId", buildingId);
details.put("userId", userId);
details.put("role", role);
authToken.setDetails(details);
```

### 2. ChannelService
**Fichier:** `src/main/java/be/delomid/oneapp/mschat/mschat/service/ChannelService.java`

**Modifications:**
- `getCurrentBuildingFromContext()` extrait maintenant le buildingId depuis les détails HTTP
- `getUserChannels()` vérifie que buildingId n'est jamais null
- Ajout de logs détaillés pour le debugging

### 3. MessageService
**Fichier:** `src/main/java/be/delomid/oneapp/mschat/mschat/service/MessageService.java`

**Modifications:**
- `getCurrentBuildingFromContext()` mis à jour
- `validateChannelBuildingAccess()` vérifie que le canal appartient au bâtiment actuel

### 4. VoteService
**Fichier:** `src/main/java/be/delomid/oneapp/mschat/mschat/service/VoteService.java`

**Modifications:**
- Ajout de `validateChannelBuildingAccess()` pour tous les votes
- `createVote()`, `getChannelVotes()`, `getVoteById()`, `submitVote()` vérifient le contexte

### 5. ChannelRepository
**Fichier:** `src/main/java/be/delomid/oneapp/mschat/mschat/repository/ChannelRepository.java`

**Modification:** La requête `findChannelsByUserIdAndBuilding` filtre mieux:
```sql
AND (c.buildingId = :buildingId OR (c.buildingId IS NULL AND c.type = 'PUBLIC'))
```

### 6. SecurityContextUtil (nouveau)
**Fichier:** `src/main/java/be/delomid/oneapp/mschat/mschat/util/SecurityContextUtil.java`

Classe utilitaire pour extraire le contexte de sécurité de manière centralisée.

## Flux d'authentification

1. **Connexion:** L'utilisateur se connecte
2. **Sélection immeuble:** L'utilisateur choisit un immeuble
3. **JWT généré:** Le backend génère un JWT avec `buildingId`
4. **Requêtes filtrées:** Toutes les requêtes sont filtrées par ce `buildingId`
5. **Changement d'immeuble:** Génération d'un nouveau JWT avec le nouveau `buildingId`

## Logs de débogage

Pour diagnostiquer les problèmes, vérifier les logs:
- `Current building from JWT: {buildingId}`
- `Fetching channels for userId: {userId} and buildingId: {buildingId}`
- `Found {count} channels for user {userId} in building {buildingId}`

## Tests recommandés

1. Se connecter avec un utilisateur ayant plusieurs immeubles
2. Vérifier que seuls les channels du premier immeuble sont visibles
3. Changer d'immeuble
4. Vérifier que SEULS les channels du nouvel immeuble sont visibles
5. Vérifier les messages, votes, fichiers suivent le même comportement

---

# Gestion des documents et dossiers par immeuble

## Comportement actuel

### Principe de fonctionnement
Le système de gestion des documents et dossiers fonctionne avec les règles suivantes :

1. **Stockage par appartement** : Les dossiers et fichiers sont créés et stockés **par appartement**
   - Chemin physique : `apartment_{apartmentId}/...`
   - Les entités `Folder` et `Document` ont une relation avec `Apartment` ET `Building`

2. **Filtrage par immeuble** : L'affichage des dossiers et fichiers est filtré par l'**immeuble sélectionné**
   - Quand un utilisateur change d'immeuble, il voit TOUS les dossiers de TOUS les appartements de cet immeuble
   - Quand un utilisateur change d'immeuble, les dossiers de l'ancien immeuble disparaissent

### Fonctionnalités

#### Création de dossiers
- L'utilisateur doit avoir un appartement associé
- L'appartement doit appartenir à l'immeuble sélectionné (vérifié)
- Le dossier est créé dans `apartment_{apartmentId}/`
- Le dossier est lié à l'**appartement** ET à l'**immeuble**

#### Affichage des dossiers
- Liste filtrée par `buildingId` (immeuble sélectionné)
- Affiche les dossiers de TOUS les appartements de l'immeuble
- Quand l'utilisateur change d'immeuble, la liste change automatiquement

#### Upload de fichiers
- L'utilisateur doit avoir un appartement dans l'immeuble sélectionné
- Le fichier est stocké dans le dossier de l'appartement
- Le document est lié à l'**appartement** ET à l'**immeuble**

#### Téléchargement, suppression et recherche
- Toutes les opérations vérifient que le document appartient à l'immeuble sélectionné
- Impossible d'accéder aux documents d'un autre immeuble

## Architecture

### Base de données

Les tables `folders` et `documents` ont :
- `apartment_id` (nullable) : Lien vers l'appartement propriétaire
- `building_id` (NOT NULL) : Lien vers l'immeuble pour le filtrage

### Sécurité

La sécurité est assurée par :
1. **Extraction du buildingId du JWT** : `SecurityContextUtil.getCurrentBuildingId()`
2. **Filtrage au niveau repository** : Toutes les requêtes incluent `building_id`
3. **Validation** : Vérification que l'appartement de l'utilisateur appartient à l'immeuble sélectionné

## Avantages de cette approche

1. **Isolation par immeuble** : Les utilisateurs ne voient que les documents de l'immeuble sélectionné
2. **Traçabilité** : On sait quel appartement a créé quel dossier/fichier
3. **Flexibilité** : Un utilisateur peut changer d'immeuble et voir les documents de cet immeuble
4. **Sécurité** : Impossible d'accéder aux documents d'un autre immeuble

## Scénarios d'utilisation

### Scénario 1 : Utilisateur avec un appartement dans l'immeuble A
1. L'utilisateur sélectionne l'immeuble A
2. Il crée un dossier "Documents Syndic"
3. Le dossier est stocké dans `apartment_{id_appartement_A}/Documents Syndic`
4. Le dossier est visible par tous les résidents de l'immeuble A

### Scénario 2 : Utilisateur change d'immeuble
1. L'utilisateur était dans l'immeuble A
2. Il sélectionne l'immeuble B
3. Les dossiers de l'immeuble A disparaissent
4. Les dossiers de l'immeuble B apparaissent
5. S'il a un appartement dans l'immeuble B, il peut créer des dossiers

### Scénario 3 : Utilisateur sans appartement dans l'immeuble sélectionné
1. L'utilisateur sélectionne un immeuble où il n'a pas d'appartement
2. Il peut VOIR les dossiers de l'immeuble
3. Il NE PEUT PAS créer de dossiers (erreur: "Aucun appartement associé")
4. Il NE PEUT PAS uploader de fichiers

## Migration SQL

Le script `migration_building_context_documents.sql` effectue :
1. Ajout de la colonne `building_id` aux tables `folders` et `documents`
2. Population de `building_id` à partir de la relation `apartment.building_id`
3. Ajout des contraintes et index

## Tests recommandés - Documents

1. **Test de création** : Créer un dossier et vérifier qu'il apparaît
2. **Test de changement d'immeuble** : Changer d'immeuble et vérifier que les dossiers changent
3. **Test de sécurité** : Vérifier qu'on ne peut pas accéder aux documents d'un autre immeuble
4. **Test multi-utilisateurs** : Deux utilisateurs dans le même immeuble voient les mêmes dossiers
5. **Test multi-appartements** : Plusieurs appartements dans le même immeuble créent des dossiers visibles par tous