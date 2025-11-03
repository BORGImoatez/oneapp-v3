# Flux d'appel WebRTC corrigé

## Problème identifié

La sonnerie continuait et la communication vocale ne s'établissait pas après avoir cliqué sur "Répondre" car :

1. **Sonnerie non arrêtée** : L'écran `IncomingCallScreen` avait sa propre instance d'AudioPlayer, distincte de celle du `CallProvider`
2. **WebRTC non initialisé** : L'appelant envoyait l'offre WebRTC immédiatement après l'initiation, avant que le receveur n'ait répondu

## Solutions implémentées

### 1. Gestion unique de la sonnerie

**Problème** : Deux sonneries différentes (CallProvider + IncomingCallScreen)

**Solution** :
- Ajout d'une méthode publique `stopRingtone()` dans `CallProvider`
- `IncomingCallScreen` utilise maintenant le `CallProvider` pour stopper la sonnerie
- Suppression de l'instance `AudioPlayer` locale dans `IncomingCallScreen`

```dart
// CallProvider
Future<void> stopRingtone() async {
  await _stopRingtone();
}

// IncomingCallScreen
Future<void> _stopRinging() async {
  // ...
  final callProvider = Provider.of<CallProvider>(context, listen: false);
  await callProvider.stopRingtone();
}
```

### 2. Flux WebRTC corrigé

**Avant (incorrect)** :
```
Appelant: initiateCall() → startCall() (envoie offre)
         ↓
Receveur: reçoit notification
         ↓
Receveur: answerCall() (prépare PeerConnection)
         ↓
Receveur: attend l'offre... ❌ (déjà envoyée avant qu'il soit prêt)
```

**Après (correct)** :
```
Appelant: initiateCall() → attend
         ↓
Receveur: reçoit notification → answerCall()
         ↓
Backend:  notifie "ANSWERED" → Appelant
         ↓
Appelant: reçoit "ANSWERED" → startCall() (envoie offre)
         ↓
Receveur: reçoit offre → handleOffer() → envoie answer
         ↓
Appelant: reçoit answer → connexion établie ✓
```

## Flux détaillé étape par étape

### Étape 1 : Initiation de l'appel

**Appelant (App A)** :
```
1. Utilisateur clique "Appeler"
2. CallProvider.initiateCall() appelé
3. Backend crée l'enregistrement d'appel (status: INITIATED)
4. Backend envoie notification WebSocket + FCM → Receveur
5. Appelant joue la sonnerie d'appel
6. Appelant ATTEND (ne crée pas encore de PeerConnection)
```

**Logs attendus** :
```
CallProvider: Initiating call to <receiverId>...
CallProvider: Waiting for receiver to answer...
Ringtone playing
```

### Étape 2 : Notification au receveur

**Receveur (App B)** :
```
1. Reçoit notification (WebSocket ou FCM)
2. CallProvider._handleIncomingCall() ou _handleIncomingCallFromFCM()
3. Crée CallModel
4. Lance la sonnerie d'appel entrant
5. Affiche IncomingCallScreen
6. ATTEND que l'utilisateur réponde
```

**Logs attendus** :
```
CallProvider: Received incoming call notification (WebSocket): INITIATED
CallProvider: New incoming call from <callerId>
Ringtone playing
```

### Étape 3 : Réponse à l'appel

**Receveur (App B)** :
```
1. Utilisateur clique "Répondre"
2. IncomingCallScreen._answerCall() appelé
3. Stoppe la sonnerie via CallProvider.stopRingtone()
4. Appelle backend: CallService.answerCall()
5. Backend met à jour status: ANSWERED
6. Prépare PeerConnection via WebRTCService.answerCall()
7. Navigation vers ActiveCallScreen
8. ATTEND l'offre WebRTC
```

**Logs attendus** :
```
CallProvider: Ringtone stopped
WebRTCService: Answering call from <callerId> on channel <channelId>
WebRTCService: PeerConnection ready to receive offer
```

### Étape 4 : Backend notifie l'appelant

**Backend** :
```
1. Reçoit answerCall()
2. Met à jour call.status = ANSWERED
3. Envoie notification WebSocket → Appelant
```

### Étape 5 : Appelant démarre WebRTC

**Appelant (App A)** :
```
1. Reçoit notification status: ANSWERED
2. CallProvider._handleIncomingCall() détecte ANSWERED
3. Stoppe la sonnerie
4. Appelle WebRTCService.startCall()
5. Crée PeerConnection
6. Crée et envoie l'offre WebRTC via WebSocket
```

**Logs attendus** :
```
CallProvider: Call answered by remote user
CallProvider: Starting WebRTC connection...
WebRTCService: Starting call to <receiverId> on channel <channelId>
WebRTCService: Offer created and sent
```

### Étape 6 : Négociation WebRTC

**Receveur (App B)** :
```
1. Reçoit l'offre WebRTC via WebSocket
2. WebRTCService._handleIncomingSignal() type: 'offer'
3. WebRTCService.handleOffer() appelé
4. setRemoteDescription(offer)
5. Crée answer
6. setLocalDescription(answer)
7. Envoie answer via WebSocket
```

**Logs attendus** :
```
WebRTCService received signal: offer
WebRTCService: Handling offer
WebRTCService: Remote description set
WebRTCService: Answer created and set
WebRTCService: Answer sent
```

**Appelant (App A)** :
```
1. Reçoit answer via WebSocket
2. WebRTCService._handleIncomingSignal() type: 'answer'
3. WebRTCService.handleAnswer() appelé
4. setRemoteDescription(answer)
5. Échange de ICE candidates
6. Connexion établie
```

**Logs attendus** :
```
WebRTCService received signal: answer
WebRTCService: Handling answer
WebRTCService: Answer set as remote description
WebRTCService received signal: ice-candidate
WebRTCService: ICE candidate added
```

### Étape 7 : Connexion établie

**Les deux apps** :
```
1. PeerConnection.onConnectionState → RTCPeerConnectionStateConnected
2. CallState.connected émis
3. Audio bidirectionnel actif ✓
4. Sonneries arrêtées ✓
```

**Logs attendus** :
```
WebRTCService: Connection state changed to connected
```

## Vérifications de débogage

### Si la sonnerie ne s'arrête pas

**Vérifier** :
1. `CallProvider.stopRingtone()` est appelée
2. Les logs montrent "Ringtone stopped"
3. `_isRingtonePlaying` passe à `false`

### Si la voix ne passe pas

**Vérifier dans les logs** :

1. **L'appelant reçoit-il le statut ANSWERED ?**
   ```
   CallProvider: Call answered by remote user
   ```

2. **L'appelant démarre-t-il WebRTC après ?**
   ```
   CallProvider: Starting WebRTC connection...
   WebRTCService: Starting call to...
   ```

3. **Le receveur reçoit-il l'offre ?**
   ```
   WebRTCService received signal: offer
   ```

4. **Le receveur envoie-t-il la réponse ?**
   ```
   WebRTCService: Answer sent
   ```

5. **L'appelant reçoit-il la réponse ?**
   ```
   WebRTCService received signal: answer
   ```

6. **Les ICE candidates sont-ils échangés ?**
   ```
   WebRTCService received signal: ice-candidate
   WebRTCService: ICE candidate added
   ```

7. **La connexion est-elle établie ?**
   ```
   WebRTCService: Connection state changed to connected
   ```

### Si un signal manque

**Problèmes possibles** :
1. WebSocket déconnecté → Vérifier `debugCallSubscriptions()`
2. Backend ne route pas les signaux → Vérifier les logs Spring Boot
3. userId incorrect → Vérifier que `_remoteUserId` est correct

## Résumé des fichiers modifiés

1. **lib/providers/call_provider.dart**
   - Ajout de `stopRingtone()` publique
   - Modification de `initiateCall()` : ne démarre plus WebRTC immédiatement
   - Modification de `_handleIncomingCall()` : démarre WebRTC quand status = ANSWERED

2. **lib/screens/call/incoming_call_screen.dart**
   - Suppression de l'instance AudioPlayer locale
   - Utilisation de `CallProvider.stopRingtone()`
   - Import de `Provider` et `CallProvider`

3. **lib/services/notification_service.dart**
   - Gestion robuste des données FCM avec valeurs par défaut
   - Validation des données essentielles

4. **lib/services/fcm_service.java** (Backend)
   - Ajout de `sendIncomingCallNotification()`

5. **lib/service/call_service.java** (Backend)
   - Envoi simultané WebSocket + FCM lors de l'initiation d'appel
