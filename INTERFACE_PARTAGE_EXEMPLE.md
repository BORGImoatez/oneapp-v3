# Interface de gestion des permissions - Exemple visuel

## Vue d'ensemble de l'écran

```
┌──────────────────────────────────────────────────────────┐
│  ← Gérer les permissions               [Enregistrer]     │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  ┌────────────────────────────────────────────────────┐  │
│  │ 📁                                                  │  │
│  │    Documents Travaux                               │  │
│  │    3 fichier(s)                                    │  │
│  └────────────────────────────────────────────────────┘  │
│                                                           │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Type de partage                                     │  │
│  │                                                      │  │
│  │ ⚪ 🔒 Privé                                         │  │
│  │      Visible uniquement par le créateur            │  │
│  │                                                      │  │
│  │ ⚪ 👥 Tous les résidents de l'immeuble             │  │
│  │      Tous les résidents peuvent voir               │  │
│  │      (lecture seule)                               │  │
│  │                                                      │  │
│  │ ⦿ 👤 Résidents spécifiques                         │  │
│  │      Sélectionner les résidents avec               │  │
│  │      permissions personnalisées                    │  │
│  └────────────────────────────────────────────────────┘  │
│                                                           │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Autoriser l'upload                    ──────○      │  │
│  │ Les résidents peuvent ajouter des fichiers         │  │
│  └────────────────────────────────────────────────────┘  │
│                                                           │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Filtres                                             │  │
│  │                                                      │  │
│  │ 🔍 │ Rechercher par nom ou prénom...          [×]  │  │
│  │ ──────────────────────────────────────────────────│  │
│  │                                                      │  │
│  │ 🏢 │ Filtrer par étage        [Tous les étages ▼]│  │
│  │ ──────────────────────────────────────────────────│  │
│  └────────────────────────────────────────────────────┘  │
│                                                           │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Résidents                    2  [Tout sélectionner]│  │
│  │                                                      │  │
│  │ ☑  Jean Dupont                                      │  │
│  │    Appt 302 - Étage 3                              │  │
│  │                                                      │  │
│  │ ☐  Marie Martin                                     │  │
│  │    Appt 405 - Étage 4                              │  │
│  │                                                      │  │
│  │ ☑  Pierre Durand                                    │  │
│  │    Appt 301 - Étage 3                              │  │
│  │                                                      │  │
│  │ ☐  Sophie Lefebvre                                  │  │
│  │    Appt 203 - Étage 2                              │  │
│  │                                                      │  │
│  │ ☐  Thomas Blanc                                     │  │
│  │    Appt 104 - Étage 1                              │  │
│  │                                                      │  │
│  │ ☐  Isabelle Moreau                                  │  │
│  │    Appt 305 - Étage 3                              │  │
│  └────────────────────────────────────────────────────┘  │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

## Détails de l'interface

### En-tête
- Bouton retour pour revenir à la liste des dossiers
- Titre "Gérer les permissions"
- Bouton "Enregistrer" pour sauvegarder les modifications

### Section "Informations du dossier"
- Icône de dossier
- Nom du dossier
- Nombre de fichiers contenus

### Section "Type de partage"
- Trois options mutuellement exclusives (radio buttons)
- Descriptions claires pour chaque option
- L'option sélectionnée est marquée avec ⦿

### Section "Autoriser l'upload"
- Toggle switch activable/désactivable
- Visible uniquement quand "Résidents spécifiques" est sélectionné
- Description de la fonctionnalité

### Section "Filtres"
- **Champ de recherche** :
  - Icône de recherche
  - Placeholder : "Rechercher par nom ou prénom..."
  - Bouton × pour effacer la recherche
  - Recherche en temps réel

- **Filtre par étage** :
  - Icône d'immeuble
  - Menu déroulant avec tous les étages disponibles
  - Option "Tous les étages" pour désactiver le filtre

### Section "Résidents"
- Badge avec le nombre de résidents sélectionnés
- Bouton "Tout sélectionner" / "Tout désélectionner"
- Liste scrollable des résidents
- Pour chaque résident :
  - Checkbox pour la sélection
  - Nom complet en gras
  - Information d'appartement et étage en gris
  - Format : "Appt [numéro] - Étage [étage]"

## États de l'interface

### État 1 : Type "Privé" sélectionné
- Sections "Autoriser l'upload", "Filtres" et "Résidents" masquées
- Seule la section "Type de partage" est visible

### État 2 : Type "Tous les résidents" sélectionné
- Sections "Autoriser l'upload", "Filtres" et "Résidents" masquées
- Note : Tous les résidents ont automatiquement accès en lecture seule

### État 3 : Type "Résidents spécifiques" sélectionné
- Toutes les sections sont visibles
- Les résidents peuvent être filtrés et sélectionnés
- L'option "Autoriser l'upload" est configurable

## Exemple d'utilisation avec filtres

### Scénario : Partager avec tous les résidents de l'étage 3

1. Sélectionner "Résidents spécifiques"
2. Dans "Filtrer par étage", choisir "Étage 3"
3. Cliquer sur "Tout sélectionner"
4. Activer "Autoriser l'upload" si nécessaire
5. Cliquer sur "Enregistrer"

Résultat :
```
┌────────────────────────────────────────────────────┐
│ Filtres                                             │
│                                                      │
│ 🔍 │                                           [×]  │
│ ──────────────────────────────────────────────────│
│                                                      │
│ 🏢 │ Filtrer par étage            [Étage 3    ▼]│
│ ──────────────────────────────────────────────────│
└────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────┐
│ Résidents                    3  [Tout désélection.]│
│                                                      │
│ ☑  Jean Dupont                                      │
│    Appt 302 - Étage 3                              │
│                                                      │
│ ☑  Pierre Durand                                    │
│    Appt 301 - Étage 3                              │
│                                                      │
│ ☑  Isabelle Moreau                                  │
│    Appt 305 - Étage 3                              │
└────────────────────────────────────────────────────┘
```

### Scénario : Rechercher "Marie"

1. Dans le champ de recherche, taper "Marie"
2. La liste se filtre automatiquement

Résultat :
```
┌────────────────────────────────────────────────────┐
│ Filtres                                             │
│                                                      │
│ 🔍 │ Marie                                     [×]  │
│ ──────────────────────────────────────────────────│
│                                                      │
│ 🏢 │ Filtrer par étage        [Tous les étages ▼]│
│ ──────────────────────────────────────────────────│
└────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────┐
│ Résidents                    0  [Tout sélectionner]│
│                                                      │
│ ☐  Marie Martin                                     │
│    Appt 405 - Étage 4                              │
│                                                      │
│ ☐  Marie-Claire Dubois                             │
│    Appt 501 - Étage 5                              │
└────────────────────────────────────────────────────┘
```

## Interactions

### Cliquer sur un résident
- Toggle la checkbox (sélection/désélection)
- Met à jour le compteur de résidents sélectionnés

### Cliquer sur "Tout sélectionner"
- Si aucun résident filtré n'est sélectionné : Sélectionne tous les résidents affichés
- Si tous les résidents filtrés sont sélectionnés : Désélectionne tous les résidents affichés
- Le texte du bouton change dynamiquement

### Modifier les filtres
- La liste des résidents se met à jour en temps réel
- Les sélections précédentes sont conservées
- Les filtres peuvent être combinés

### Cliquer sur "Enregistrer"
- Valide et enregistre les modifications
- Affiche un message de succès
- Retourne à l'écran précédent
- Rafraîchit la liste des dossiers

### Cliquer sur le bouton retour
- Annule les modifications non enregistrées
- Retourne à l'écran précédent
- Peut demander confirmation si des modifications ont été faites
