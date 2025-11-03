import 'package:flutter/foundation.dart';
import '../models/call_model.dart';
import '../services/call_service.dart';
import '../services/webrtc_service.dart';
import '../services/websocket_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'package:audioplayers/audioplayers.dart';

class CallProvider with ChangeNotifier {
  final CallService _callService = CallService();
  final WebRTCService _webrtcService = WebRTCService();

  CallModel? _currentCall;
  bool _isInCall = false;
  List<CallModel> _callHistory = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRingtonePlaying = false;
  WebSocketService? _webSocketService;

  CallModel? get currentCall => _currentCall;
  bool get isInCall => _isInCall;
  List<CallModel> get callHistory => _callHistory;
  WebRTCService get webrtcService => _webrtcService;

  void initialize(WebSocketService webSocketService) async {
    print('CallProvider: Starting initialization...');

    _webSocketService = webSocketService;

    // Enregistrer un callback pour les reconnexions WebSocket
    _webSocketService!.onConnected = _onWebSocketReconnected;
    print('CallProvider: onConnected callback registered for reconnections');

    // Enregistrer les callbacks d'appel
    _registerCallCallbacks();

    // Enregistrer le callback FCM pour les appels entrants
    NotificationService().onIncomingCallReceived = _handleIncomingCallFromFCM;
    print('CallProvider: FCM incoming call callback registered');

    // Initialiser WebRTC avec WebSocket
    await _webrtcService.initialize(_webSocketService!);
    print('CallProvider: WebRTC service initialized');

    // Re-souscrire aux signaux d'appel pour s'assurer que le callback est actif
    _webSocketService!.ensureCallSignalsSubscription();
    print('CallProvider: Call signals subscription ensured');

    // Debug pour vérifier l'état
    _webSocketService!.debugCallSubscriptions();

    print('CallProvider initialized successfully');
  }

  void _onWebSocketReconnected() {
    print('CallProvider: WebSocket reconnected, re-registering callbacks');
    _registerCallCallbacks();
    _webSocketService!.ensureCallSignalsSubscription();
    _webSocketService!.debugCallSubscriptions();
  }

  void _registerCallCallbacks() {
    _webSocketService!.onIncomingCall = _handleIncomingCall;
    print('CallProvider: Call callbacks registered');
  }

  void _ensureCallbacksRegistered() {
    if (_webSocketService != null) {
      print('CallProvider: Re-registering callbacks after call ended');
      _registerCallCallbacks();
      _webrtcService.initialize(_webSocketService!);
      _webSocketService!.ensureCallSignalsSubscription();
      _webSocketService!.debugCallSubscriptions();
      print('CallProvider: Callbacks re-registered successfully');
    }
  }

  void _handleIncomingCall(Map<String, dynamic> callData) {
    try {
      print('CallProvider: Received incoming call notification (WebSocket): ${callData['status']}');
      final call = CallModel.fromJson(callData);

      if (call.status == 'INITIATED' && _currentCall == null) {
        print('CallProvider: New incoming call from ${call.callerId}');
        _currentCall = call;
        _playRingtoneIncome();
        notifyListeners();
      } else if (call.status == 'ANSWERED' || call.status == 'ENDED' || call.status == 'REJECTED') {
        if (_currentCall?.id == call.id) {
          if (call.status == 'ENDED' || call.status == 'REJECTED') {
            print('CallProvider: Call ended or rejected, cleaning up');
            _stopRingtone();
            _currentCall = null;
            _isInCall = false;
            _ensureCallbacksRegistered();
          } else if (call.status == 'ANSWERED') {
            print('CallProvider: Call answered by remote user');
            _stopRingtone();
            _currentCall = call;
            _isInCall = true;

            // L'appelant doit maintenant envoyer l'offre WebRTC
            print('CallProvider: Starting WebRTC connection...');
            _webrtcService.startCall(
              call.channelId.toString(),
              call.receiverId,
            ).catchError((e) {
              print('CallProvider: Error starting WebRTC: $e');
            });
          }
          notifyListeners();
        }
      }
    } catch (e) {
      print('CallProvider: Error handling incoming call: $e');
    }
  }

  void _handleIncomingCallFromFCM(Map<String, dynamic> callData) {
    try {
      print('CallProvider: Received incoming call notification (FCM): $callData');

      if (_currentCall != null) {
        print('CallProvider: Call already in progress, ignoring FCM notification');
        return;
      }

      // Récupérer l'utilisateur actuel pour les infos du receveur
      final currentUser = StorageService.getUser();
      if (currentUser == null) {
        print('CallProvider: No current user found, cannot process incoming call');
        return;
      }

      // Construire le CallModel avec les données FCM
      final call = CallModel(
        id: callData['id'],
        channelId: callData['channelId'],
        callerId: callData['callerId'],
        callerName: callData['callerName'],
        callerAvatar: callData['callerAvatar'],
        receiverId: currentUser.id,
        receiverName: '${currentUser.firstName} ${currentUser.lastName}',
        receiverAvatar: currentUser.pictureUrl,
        status: callData['status'],
        createdAt: DateTime.now(),
      );

      print('CallProvider: New incoming call from FCM: ${call.callerId}');
      _currentCall = call;
      _playRingtoneIncome();
      notifyListeners();
    } catch (e, stackTrace) {
      print('CallProvider: Error handling incoming call from FCM: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _playRingtoneIncome() async {
    if (_isRingtonePlaying) return;

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(UrlSource('https://soft-verse.com/son/nokia_remix.mp3'));
      _isRingtonePlaying = true;
      print('Ringtone playing');
    } catch (e) {
      print('Error playing ringtone: $e');
    }
  }
  Future<void> _playRingtone() async {
    if (_isRingtonePlaying) return;

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(UrlSource('https://soft-verse.com/son/son.mp3'));
      _isRingtonePlaying = true;
      print('Ringtone playing');
    } catch (e) {
      print('Error playing ringtone: $e');
    }
  }

  Future<void> _stopRingtone() async {
    if (!_isRingtonePlaying) return;

    try {
      await _audioPlayer.stop();
      _isRingtonePlaying = false;
      print('Ringtone stopped');
    } catch (e) {
      print('Error stopping ringtone: $e');
    }
  }

  // Méthode publique pour stopper la sonnerie (appelée depuis l'UI)
  Future<void> stopRingtone() async {
    await _stopRingtone();
  }

  Future<void> initiateCall({
    required int channelId,
    required String receiverId,
  }) async {
    try {
      print('Initiating call to $receiverId...');

      // Vérifier l'état des souscriptions avant l'appel
      _webSocketService?.debugCallSubscriptions();

      final call = await _callService.initiateCall(
        channelId: channelId,
        receiverId: receiverId,
      );

      _currentCall = call;
      _isInCall = true;

      await _playRingtone();

      // Ne pas envoyer l'offre WebRTC immédiatement
      // L'offre sera envoyée quand le receveur répond (statut ANSWERED)
      print('CallProvider: Waiting for receiver to answer...');

      notifyListeners();
    } catch (e) {
      print('Error initiating call: $e');
      await _stopRingtone();
      rethrow;
    }
  }

  Future<void> answerCall(CallModel call) async {
    try {
      await _stopRingtone();

      // 1. Notifier le serveur qu'on répond
      final updatedCall = await _callService.answerCall(call.id!);

      _currentCall = updatedCall;
      _isInCall = true;

      // 2. Préparer le PeerConnection pour recevoir l'offre
      await _webrtcService.answerCall(
        call.channelId.toString(),
        call.callerId,
      );

      // 3. Le WebRTCService va maintenant écouter et traiter l'offre automatiquement
      print('Ready to receive WebRTC offer from ${call.callerId}');

      notifyListeners();
    } catch (e) {
      print('Error answering call: $e');
      await _stopRingtone();
      rethrow;
    }
  }

  Future<void> endCall() async {
    if (_currentCall == null) return;

    try {
      await _stopRingtone();
      await _callService.endCall(_currentCall!.id!);
      await _webrtcService.endCall();

      _currentCall = null;
      _isInCall = false;

      // Réenregistrer les callbacks pour le prochain appel
      _ensureCallbacksRegistered();

      print('Call ended, WebRTC cleaned up and ready for next call');
      notifyListeners();
    } catch (e) {
      print('Error ending call: $e');
      await _stopRingtone();
      _currentCall = null;
      _isInCall = false;
      _ensureCallbacksRegistered();
      notifyListeners();
    }
  }

  Future<void> rejectCall(CallModel call) async {
    try {
      await _stopRingtone();
      await _callService.rejectCall(call.id!);

      if (_currentCall?.id == call.id) {
        _currentCall = null;
        _isInCall = false;
      }

      // Réenregistrer les callbacks pour le prochain appel
      _ensureCallbacksRegistered();

      print('Call rejected, ready for next call');
      notifyListeners();
    } catch (e) {
      print('Error rejecting call: $e');
      await _stopRingtone();
      _currentCall = null;
      _isInCall = false;
      _ensureCallbacksRegistered();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadCallHistory(int channelId) async {
    try {
      _callHistory = await _callService.getCallHistory(channelId);
      notifyListeners();
    } catch (e) {
      print('Error loading call history: $e');
    }
  }

  void handleIncomingCall(CallModel call) {
    _currentCall = call;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopRingtone();
    _audioPlayer.dispose();
    _webrtcService.dispose();
    super.dispose();
  }
}
