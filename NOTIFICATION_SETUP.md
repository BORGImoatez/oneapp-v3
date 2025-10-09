# Configuration des Notifications Push

## Vue d'ensemble
L'implémentation complète des notifications push a été ajoutée au système. Lorsqu'un administrateur crée un canal, tous les résidents de l'immeuble reçoivent une notification push contenant le nom et prénom de l'administrateur ainsi que le sujet du canal.

## Configuration Backend

### 1. Dépendances
- Firebase Admin SDK (v9.2.0) ajouté dans `pom.xml`

### 2. Base de données
- Nouvelle colonne `fcm_token` ajoutée à la table `residents`
- Migration SQL créée : `V1__Add_fcm_token_to_residents.sql`

### 3. Service FCMService
Un nouveau service `FCMService.java` a été créé pour gérer les notifications push :
- Initialisation de Firebase Admin SDK
- Envoi de notifications à un ou plusieurs tokens
- Gestion des envois par batch (max 500 tokens par batch)
- Gestion des erreurs et logging

### 4. Endpoint d'enregistrement du token
- Nouveau endpoint : `POST /auth/update-fcm-token`
- Permet aux clients d'enregistrer leur token FCM
- DTO : `UpdateFcmTokenRequest.java`

### 5. Intégration dans ChannelService
- Lors de la création d'un canal, la méthode `sendChannelCreationNotifications()` est appelée
- Récupère tous les résidents de l'immeuble
- Filtre ceux qui ont un token FCM
- Envoie une notification avec :
  - Titre : "Nouveau canal créé"
  - Corps : "[Prénom Nom] a créé un canal pour le sujet : [Nom du canal]"
  - Données : channelId et type (CHANNEL_CREATED)

## Configuration Frontend (Flutter)

### 1. Service NotificationService
Le service `notification_service.dart` a été mis à jour avec :
- Récupération et stockage du token FCM
- Envoi automatique du token au backend
- Gestion du rafraîchissement du token
- Gestion des notifications (foreground et background)
- Navigation vers le canal lors du tap sur la notification

### 2. ApiService
- Nouvelle méthode `updateFcmToken()` pour envoyer le token au backend

### 3. Initialisation
Le service de notification est initialisé dans `main.dart` au démarrage de l'application

## Configuration Firebase

### Étapes pour activer les notifications :

1. **Obtenir le fichier de configuration Firebase** :
   - Aller sur [Firebase Console](https://console.firebase.google.com/)
   - Sélectionner votre projet
   - Aller dans "Project Settings" > "Service accounts"
   - Cliquer sur "Generate new private key"
   - Télécharger le fichier JSON

2. **Placer le fichier sur le serveur** :
   ```bash
   # Exemple de chemin
   /etc/mschat/firebase-service-account.json
   ```

3. **Configurer le chemin dans application.properties** :
   ```properties
   firebase.config.path=/etc/mschat/firebase-service-account.json
   ```

4. **Redémarrer l'application backend**

## Format de notification

### Structure de la notification envoyée :
```json
{
  "notification": {
    "title": "Nouveau canal créé",
    "body": "Jean Dupont a créé un canal pour le sujet : Réunion des copropriétaires"
  },
  "data": {
    "channelId": "123",
    "type": "CHANNEL_CREATED"
  },
  "android": {
    "priority": "HIGH",
    "notification": {
      "sound": "default",
      "channel_id": "channel_notifications"
    }
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "default"
      }
    }
  }
}
```

## Test des notifications

### 1. Vérifier que le token FCM est enregistré :
```bash
# Dans les logs backend, vous devriez voir :
FCM token updated for user: user@example.com
```

### 2. Créer un canal et vérifier l'envoi :
```bash
# Dans les logs backend :
Sent X notifications for channel creation
```

### 3. Vérifier la réception sur le client :
- Les logs Flutter montrent le token FCM
- La notification apparaît sur l'appareil

## Sécurité

- Le token FCM est stocké de manière sécurisée dans la base de données
- Seul l'utilisateur authentifié peut mettre à jour son propre token
- Les tokens sont filtrés avant l'envoi (tokens vides ignorés)
- La création de canal nécessite les permissions appropriées

## Dépannage

### Le token FCM n'est pas envoyé au backend :
- Vérifier que l'utilisateur est authentifié
- Vérifier la configuration Firebase dans l'application Flutter
- Vérifier les permissions de notification

### Les notifications ne sont pas reçues :
- Vérifier que le fichier de configuration Firebase est correctement placé
- Vérifier les logs du backend pour les erreurs Firebase
- Vérifier que les tokens FCM sont bien enregistrés dans la base de données

### Firebase n'est pas initialisé :
- Vérifier le chemin du fichier de configuration dans application.properties
- Vérifier les permissions du fichier
- Redémarrer l'application backend
