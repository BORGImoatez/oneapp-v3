# Corrections de la signalisation WebRTC

## Problèmes identifiés et corrigés

### 1. Souscription tardive aux signaux d'appel

**Problème**: Dans `WebSocketService`, la méthode `_subscribeToCallSignals()` n'était appelée que dans `_onConnect()`. Si le récepteur se connectait après l'envoi de l'offre, il ne recevait jamais le signal initial.

**Solution**:
- Ajout d'une méthode publique `ensureCallSignalsSubscription()` dans `WebSocketService`
- Cette méthode permet de s'abonner aux signaux même si déjà connecté
- Appelée lors de l'initialisation du `WebRTCService`

```dart
// websocket_service.dart
void ensureCallSignalsSubscription() {
  if (_isConnected) {
    _subscribeToCallSignals();
  }
}
```

### 2. Gestion manquante des signaux entrants dans WebRTCService

**Problème**: Dans `WebRTCService.startCall()`, l'offre était créée et envoyée, mais il n'y avait pas de code qui écoutait les signaux entrants (`onCallSignalReceived`).

**Solution**:
- `WebRTCService` gère maintenant directement les signaux entrants via `_handleIncomingSignal()`
- Abonnement automatique lors de l'initialisation
- Traitement des types de signaux: `offer`, `answer`, `ice-candidate`, `end-call`

```dart
// webrtc_service.dart
Future<void> initialize(WebSocketService webSocketService) async {
  if (_isInitialized) return;

  _webSocketService = webSocketService;

  // Écouter les signaux WebRTC entrants
  _webSocketService!.onCallSignalReceived = _handleIncomingSignal;

  // S'assurer que la souscription est active
  _webSocketService!.ensureCallSignalsSubscription();

  _isInitialized = true;
}

void _handleIncomingSignal(Map<String, dynamic> signal) async {
  final type = signal['type'];
  final data = signal['data'];

  switch (type) {
    case 'offer':
      if (_peerConnection != null) {
        await handleOffer(data['sdp']);
      }
      break;
    case 'answer':
      await handleAnswer(data['sdp']);
      break;
    case 'ice-candidate':
      await handleIceCandidate(data['candidate']);
      break;
    case 'end-call':
      await endCall();
      break;
  }
}
```

### 3. Séquence d'initialisation incorrecte pour le récepteur

**Problème**: Le récepteur devait:
1. Recevoir la notification d'appel via `/user/queue/call`
2. Appeler `answerCall()` pour créer le PeerConnection
3. Recevoir l'offre via `/user/queue/signal`
4. Créer et envoyer la réponse

Mais dans `answerCall()`, l'offre reçue n'était pas gérée.

**Solution**:
- `answerCall()` crée maintenant le PeerConnection et attend l'offre
- État mis à `CallState.ringing` au lieu de `CallState.connected`
- L'offre est traitée automatiquement par `_handleIncomingSignal()`
- La réponse est créée et envoyée après réception de l'offre

```dart
// webrtc_service.dart
Future<void> answerCall(String channelId, String remoteUserId) async {
  _remoteUserId = remoteUserId;
  _currentCallId = channelId;

  // Créer le PeerConnection et attendre
  await _createPeerConnection();

  // Ne pas marquer comme connecté immédiatement, attendre l'offre
  _callStateController.add(CallState.ringing);

  print('WebRTCService: PeerConnection ready to receive offer');
}
```

### 4. Simplification du CallProvider

**Problème**: Le `CallProvider` dupliquait la gestion des signaux déjà prise en charge par `WebRTCService`.

**Solution**:
- Suppression de `_handleCallSignal()` dans `CallProvider`
- Délégation complète au `WebRTCService`
- `CallProvider` ne gère que les notifications d'appel (`onIncomingCall`)

```dart
// call_provider.dart
void initialize(WebSocketService webSocketService) async {
  // Initialiser WebRTC avec WebSocket
  await _webrtcService.initialize(webSocketService);

  // Le WebRTCService gère déjà onCallSignalReceived
  // On écoute juste les notifications d'appel
  webSocketService.onIncomingCall = _handleIncomingCall;
}
```

## Flux corrigé de signalisation

### Appelant (Caller)

1. L'utilisateur initie un appel via `CallProvider.initiateCall()`
2. `CallService.initiateCall()` notifie le serveur
3. `WebRTCService.startCall()` crée le PeerConnection et l'offre
4. L'offre est envoyée via WebSocket: `/app/call.signal` → `/user/queue/signal` (récepteur)
5. Les ICE candidates sont envoyés au fur et à mesure
6. Réception de la réponse (answer) via `/user/queue/signal`
7. `_handleIncomingSignal()` traite la réponse automatiquement
8. Connexion établie

### Récepteur (Receiver)

1. Réception de la notification d'appel via `/user/queue/call`
2. `_handleIncomingCall()` met à jour l'état et affiche `IncomingCallScreen`
3. L'utilisateur accepte l'appel
4. `CallService.answerCall()` notifie le serveur
5. `WebRTCService.answerCall()` crée le PeerConnection (prêt à recevoir)
6. Réception de l'offre via `/user/queue/signal`
7. `_handleIncomingSignal('offer')` traite l'offre:
   - `setRemoteDescription(offer)`
   - `createAnswer()`
   - `setLocalDescription(answer)`
   - Envoi de la réponse via WebSocket
8. Les ICE candidates sont reçus et traités
9. Connexion établie

## Logs de débogage ajoutés

Des logs détaillés ont été ajoutés à chaque étape pour faciliter le diagnostic:

- `WebRTCService: Starting call to [userId] on channel [channelId]`
- `WebRTCService: Call started, offer sent`
- `WebRTCService: Answering call from [userId] on channel [channelId]`
- `WebRTCService: PeerConnection ready to receive offer`
- `WebRTCService received signal: [type]`
- `WebRTCService: Handling offer`
- `WebRTCService: Answer sent`
- `WebRTCService: Handling answer`
- `WebRTCService: Handling ICE candidate`

## Points critiques

1. **Ordre des opérations**: Le PeerConnection doit être créé AVANT de recevoir l'offre
2. **Souscription précoce**: Les signaux WebRTC doivent être écoutés dès l'initialisation
3. **Gestion centralisée**: Un seul point de traitement des signaux (WebRTCService)
4. **États corrects**: `ringing` pour le récepteur en attente, `calling` pour l'appelant
5. **Logs exhaustifs**: Facilite le débogage des problèmes de signalisation

## Tests recommandés

1. Appel avec les deux utilisateurs déjà connectés
2. Appel avec le récepteur se connectant après l'initiation
3. Appel avec perte de connexion réseau temporaire
4. Plusieurs appels successifs
5. Rejet d'appel
6. Fin d'appel par l'appelant
7. Fin d'appel par le récepteur
