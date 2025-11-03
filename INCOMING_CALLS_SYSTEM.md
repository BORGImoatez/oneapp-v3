# Système d'appels entrants avec fallback FCM

## Vue d'ensemble

Le système d'appels vocaux utilise une approche hybride pour garantir que les appels entrants sont toujours reçus :

1. **WebSocket (méthode principale)** : Notification en temps réel via STOMP WebSocket
2. **FCM (fallback)** : Notification push Firebase si le WebSocket échoue ou est déconnecté

## Architecture

### Backend (Spring Boot)

#### CallService.java
Lors de l'initiation d'un appel, le service :
1. Crée l'enregistrement d'appel en base de données
2. Envoie une notification WebSocket au receveur via `/user/queue/call`
3. **Envoie également une notification FCM** comme fallback

```java
// Notification WebSocket
messagingTemplate.convertAndSendToUser(receiverId, "/queue/call", callDto);

// Notification FCM (fallback)
fcmService.sendIncomingCallNotification(
    receiverFcmToken,
    callerId,
    callerName,
    callerAvatar,
    callId,
    channelId
);
```

#### FCMService.java
Nouvelle méthode `sendIncomingCallNotification()` avec :
- Priorité MAX pour Android
- Canal de notification `incoming_call_channel`
- Données complètes de l'appel dans le payload
- Configuration pour réveiller l'app en arrière-plan

### Frontend (Flutter)

#### NotificationService.dart
- Nouveau canal de notification haute priorité : `incoming_call_channel`
- Callback `onIncomingCallReceived` pour transmettre l'appel au CallProvider
- Gestion des notifications en foreground et background

#### CallProvider.dart
Deux méthodes de réception d'appels :

1. **_handleIncomingCall()** : Réception via WebSocket
2. **_handleIncomingCallFromFCM()** : Réception via FCM (fallback)

Les deux méthodes :
- Créent un CallModel à partir des données reçues
- Lancent la sonnerie avec `_playRingtoneIncome()`
- Affichent l'écran d'appel entrant

#### main.dart
Handler pour les notifications en arrière-plan :
```dart
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  if (message.data['type'] == 'INCOMING_CALL') {
    // L'app se réveille et traite l'appel
  }
}
```

## Flux d'appel entrant

### Scénario 1 : WebSocket connecté (optimal)
```
1. Utilisateur A lance l'appel
2. Backend → WebSocket → Utilisateur B
3. CallProvider._handleIncomingCall() déclenché
4. Sonnerie démarre
5. Écran d'appel entrant affiché
```

### Scénario 2 : WebSocket déconnecté (fallback FCM)
```
1. Utilisateur A lance l'appel
2. Backend → WebSocket échoue/ignoré
3. Backend → FCM → Utilisateur B
4. NotificationService reçoit la notification FCM
5. CallProvider._handleIncomingCallFromFCM() déclenché
6. Sonnerie démarre
7. Écran d'appel entrant affiché
```

### Scénario 3 : App en arrière-plan/tuée
```
1. Utilisateur A lance l'appel
2. Backend → FCM → Utilisateur B
3. Android réveille l'app
4. handleBackgroundMessage() traite la notification
5. Notification système affichée
6. Utilisateur tape sur la notification
7. App s'ouvre sur l'écran d'appel
```

## Prévention de duplication

Le système évite les doublons avec cette logique :
```dart
if (_currentCall != null) {
  print('Call already in progress, ignoring FCM notification');
  return;
}
```

Si un appel est déjà en cours via WebSocket, la notification FCM est ignorée.

## Configuration Android requise

### AndroidManifest.xml
```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
```

### Canal de notification
- ID : `incoming_call_channel`
- Nom : "Appels entrants"
- Importance : MAX
- Son : Activé
- Vibration : Activée
- Lumières : Activées

## Tests

### Test du WebSocket
1. Les deux utilisateurs ont l'app ouverte
2. WebSocket connecté (vérifier les logs)
3. Lancer un appel
4. Résultat attendu : Sonnerie instantanée

### Test du fallback FCM
1. Utilisateur B ferme l'app ou la met en arrière-plan
2. Attendre 30 secondes (WebSocket se déconnecte)
3. Utilisateur A lance un appel
4. Résultat attendu : Notification push reçue, app se réveille, sonnerie démarre

### Test de prévention de duplication
1. Les deux utilisateurs ont l'app ouverte
2. Lancer un appel
3. Vérifier les logs : doit montrer WebSocket reçu ET FCM reçu mais ignoré

## Logs de diagnostic

### Backend
```
=== CALL INITIATION DEBUG ===
Sending FCM notification to receiver token: <token>
FCM notification sent successfully
=== END CALL INITIATION DEBUG ===
```

### Flutter - WebSocket
```
CallProvider: Received incoming call notification (WebSocket): INITIATED
CallProvider: New incoming call from <userId>
Ringtone playing
```

### Flutter - FCM
```
=== HANDLING INCOMING CALL FROM FCM ===
CallProvider: Received incoming call notification (FCM): {...}
CallProvider: New incoming call from FCM: <userId>
Ringtone playing
```

## Dépannage

### Problème : Aucune notification reçue
**Vérifier :**
1. Le token FCM est bien enregistré sur le serveur
2. Firebase Cloud Messaging est configuré
3. Les permissions de notification sont accordées

### Problème : WebSocket ne reçoit pas
**Vérifier :**
1. `debugCallSubscriptions()` montre les souscriptions actives
2. Le callback `onIncomingCall` est bien défini
3. La reconnexion WebSocket réenregistre les callbacks

### Problème : FCM ne réveille pas l'app
**Vérifier :**
1. Les permissions WAKE_LOCK et USE_FULL_SCREEN_INTENT
2. Le canal de notification `incoming_call_channel` existe
3. La priorité de la notification est MAX

### Problème : "type 'Null' is not a subtype of type 'String'"
**Solution :**
Ce problème arrive quand les données FCM sont incomplètes. Le système gère maintenant automatiquement :
- Les valeurs nulles avec des valeurs par défaut (`?? ''`)
- Construction manuelle du CallModel au lieu d'utiliser `fromJson()`
- Récupération automatique des infos du receveur depuis `StorageService.getUser()`
- Validation des données essentielles (callId et channelId non nuls)

## Améliorations futures possibles

1. **Full-screen intent** : Afficher l'écran d'appel directement même si l'écran est verrouillé
2. **Timeout automatique** : Arrêter la sonnerie après X secondes
3. **Statistiques** : Logger quel canal (WebSocket vs FCM) a fonctionné
4. **Retry logic** : Réessayer la notification FCM si la première échoue
