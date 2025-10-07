# MSChat - Application de Messagerie Monolithique

Application monolithique de messagerie pour immeubles avec authentification autonome, gestion des résidents et communication temps réel via WebSockets.

## Fonctionnalités

### Authentification Autonome
- **Inscription** : Email + mot de passe avec vérification OTP
- **Connexion 2FA** : Email/mot de passe + code OTP par email
- **JWT interne** : Génération et validation de tokens JWT
- **Gestion des rôles** : RESIDENT, BUILDING_ADMIN, GROUP_ADMIN, SUPER_ADMIN

### Gestion des Immeubles
- **Immeubles** : Gestion complète avec adresses et informations détaillées
- **Appartements** : Attribution aux résidents avec caractéristiques détaillées
- **Résidents** : Profils utilisateurs liés aux appartements
- **Relations** : Système relationnel complet entre immeubles, appartements et résidents

### Types de Canaux
- **ONE_TO_ONE** : Discussion privée entre 2 utilisateurs
- **GROUP** : Groupe personnalisé créé par un utilisateur
- **BUILDING** : Canal par immeuble (1 par immeuble)
- **BUILDING_GROUP** : Canal par groupe d'immeubles (1 par groupe)
- **PUBLIC** : Canaux publics accessibles à tous

### Fonctionnalités de Messagerie
- Envoi de messages temps réel via WebSockets
- Messages avec types (TEXT, IMAGE, FILE, SYSTEM)
- Réponses aux messages
- Édition et suppression de messages
- Indicateur "en train d'écrire"
- Historique des messages avec pagination

### Administration
- **Gestion des comptes** : Approbation, rejet, blocage des inscriptions
- **Attribution d'appartements** : Assignation des résidents aux appartements
- **Admins par immeuble/groupe** : Gestion décentralisée

## Configuration

### Base de Données
```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/mschat_db
    username: postgres
    password: postgres
```

### Configuration Email
L'application utilise Gmail SMTP pour l'envoi des codes OTP.

## API Endpoints

### Authentification
- `POST /auth/register` - Inscription avec email/mot de passe
- `POST /auth/verify-registration` - Vérification OTP inscription
- `POST /auth/login` - Connexion (étape 1)
- `POST /auth/verify-login` - Vérification OTP connexion (étape 2)
- `POST /auth/refresh` - Rafraîchissement du token JWT

### Administration
- `GET /admin/pending-registrations` - Liste des demandes d'inscription
- `POST /admin/approve-registration/{id}` - Approuver une inscription
- `POST /admin/reject-registration/{id}` - Rejeter une inscription
- `POST /admin/block-account/{id}` - Bloquer un compte
- `POST /admin/unblock-account/{id}` - Débloquer un compte
- `GET /admin/building/{id}/residents` - Résidents d'un immeuble

### Immeubles
- `POST /api/v1/buildings` - Créer un immeuble
- `GET /api/v1/buildings` - Liste des immeubles
- `GET /api/v1/buildings/{id}` - Détails d'un immeuble
- `PUT /api/v1/buildings/{id}` - Modifier un immeuble
- `DELETE /api/v1/buildings/{id}` - Supprimer un immeuble
- `GET /api/v1/buildings/city/{ville}` - Immeubles par ville
- `GET /api/v1/buildings/postal-code/{code}` - Immeubles par code postal

### Appartements
- `POST /api/v1/apartments` - Créer un appartement
- `GET /api/v1/apartments/building/{buildingId}` - Appartements d'un immeuble
- `GET /api/v1/apartments/{id}` - Détails d'un appartement
- `PUT /api/v1/apartments/{id}` - Modifier un appartement
- `DELETE /api/v1/apartments/{id}` - Supprimer un appartement
- `POST /api/v1/apartments/{id}/assign/{userId}` - Assigner un résident
- `POST /api/v1/apartments/{id}/remove-resident` - Libérer un appartement
- `GET /api/v1/apartments/building/{buildingId}/available` - Appartements libres
- `GET /api/v1/apartments/building/{buildingId}/occupied` - Appartements occupés

### Résidents
- `POST /api/v1/residents` - Créer un résident
- `GET /api/v1/residents` - Liste des résidents
- `GET /api/v1/residents/{id}` - Détails d'un résident
- `PUT /api/v1/residents/{id}` - Modifier un résident
- `DELETE /api/v1/residents/{id}` - Supprimer un résident
- `GET /api/v1/residents/building/{buildingId}` - Résidents d'un immeuble
- `GET /api/v1/residents/email/{email}` - Résident par email
- `GET /api/v1/residents/search?name={name}` - Recherche par nom
- `GET /api/v1/residents/{id}/apartment` - Info appartement du résident

### Canaux
- `POST /api/v1/channels` - Créer un canal
- `GET /api/v1/channels` - Récupérer les canaux de l'utilisateur
- `GET /api/v1/channels/{id}` - Détails d'un canal
- `POST /api/v1/channels/{id}/join` - Rejoindre un canal
- `POST /api/v1/channels/{id}/leave` - Quitter un canal
- `GET /api/v1/channels/direct/{userId}` - Canal direct avec un utilisateur
- `GET /api/v1/channels/building/{buildingId}` - Canaux d'un immeuble
- `GET /api/v1/channels/building/{buildingId}/residents` - Résidents d'un immeuble
- `POST /api/v1/channels/building/{buildingId}/create` - Créer canal d'immeuble

### Messages
- `POST /api/v1/messages` - Envoyer un message
- `GET /api/v1/messages/channel/{channelId}` - Messages d'un canal
- `PUT /api/v1/messages/{id}` - Éditer un message
- `DELETE /api/v1/messages/{id}` - Supprimer un message

### WebSocket
- **Connexion** : `ws://localhost:8080/ws`
- **Envoyer un message** : `/app/message.send`
- **Typing indicator** : `/app/message.typing`
- **Écouter les messages** : `/topic/channel/{channelId}`
- **Écouter le typing** : `/topic/channel/{channelId}/typing`

## Utilisation

### 1. Inscription
```javascript
// Étape 1: Inscription
const registerResponse = await fetch('/auth/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        fname: 'John',
        lname: 'Doe',
        email: 'john@example.com',
        password: 'password123'
    })
});

// Étape 2: Vérification OTP
const verifyResponse = await fetch('/auth/verify-registration', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        email: 'john@example.com',
        otpCode: '123456'
    })
});
```

### 2. Connexion
```javascript
// Étape 1: Login
const loginResponse = await fetch('/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        email: 'john@example.com',
        password: 'password123'
    })
});

// Étape 2: Vérification OTP
const verifyLoginResponse = await fetch('/auth/verify-login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        email: 'john@example.com',
        otpCode: '654321'
    })
});

const { token } = await verifyLoginResponse.json();
```

### 1. Authentification WebSocket
```javascript
const token = "your-jwt-token"; // Obtenu après connexion
const socket = new SockJS('/ws');
const stompClient = Stomp.over(socket);

stompClient.connect({'Authorization': `Bearer ${token}`}, function(frame) {
    console.log('Connected: ' + frame);
});
```

### 2. Envoyer un Message
```javascript
// Via WebSocket
stompClient.send('/app/message.send', {}, JSON.stringify({
    'channelId': 1,
    'content': 'Hello World!',
    'type': 'TEXT'
}));

// Via REST API
fetch('/api/v1/messages', {
    method: 'POST',
    headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({
        channelId: 1,
        content: 'Hello World!',
        type: 'TEXT'
    })
});
```

### 3. Écouter les Messages
```javascript
stompClient.subscribe('/topic/channel/1', function(message) {
    const messageData = JSON.parse(message.body);
    console.log('New message:', messageData);
});
```

## Modèles de Données

### Channel
- Types : ONE_TO_ONE, GROUP, BUILDING, BUILDING_GROUP, PUBLIC
- Permissions par bâtiment/groupe de bâtiments
- Membres avec rôles (OWNER, ADMIN, MODERATOR, MEMBER)

### Message
- Types : TEXT, IMAGE, FILE, SYSTEM
- Support des réponses
- Édition et suppression avec historique

### Permissions
- Accès basé sur l'appartenance aux canaux
- Contrôle d'écriture par membre
- Validation des permissions à chaque action

## Démarrage

1. **Base de données** : Créer la base `mschat_db` dans PostgreSQL
2. **Configuration email** : Vérifier les paramètres SMTP dans `application.properties`
3. **Démarrer** : `./mvnw spring-boot:run`

L'application sera disponible sur `http://localhost:8080`

### Compte Super Admin par défaut
- Email: `admin@mschat.com`
- Mot de passe: `SuperAdmin123!`

## Endpoints utiles

- **Application Info** : `GET /info`
- **Health Check** : `GET /info/health`
- **Actuator** : `GET /actuator/health`
- **API Documentation** : `GET /swagger-ui.html`

L'application est maintenant complètement autonome et monolithique !