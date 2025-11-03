import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'websocket_service.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final _remoteStreamController = StreamController<MediaStream>.broadcast();
  final _callStateController = StreamController<CallState>.broadcast();

  Stream<MediaStream> get remoteStream => _remoteStreamController.stream;
  Stream<CallState> get callState => _callStateController.stream;

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {
        'urls': 'turn:192.168.129.187:3478',
        'username': 'testuser',
        'credential': 'testpass'
      }
    ],
    'sdpSemantics': 'unified-plan',
  };

  final Map<String, dynamic> _mediaConstraints = {
    'audio': true,
    'video': false,
  };

  WebSocketService? _webSocketService;
  String? _currentCallId;
  String? _remoteUserId;
  bool _isInitialized = false;

  Future<void> initialize(WebSocketService webSocketService) async {
    if (_isInitialized) {
      print('WebRTCService already initialized, re-registering callbacks');
      // Même si déjà initialisé, on réenregistre les callbacks
      _webSocketService!.onCallSignalReceived = _handleIncomingSignal;
      _webSocketService!.ensureCallSignalsSubscription();
      return;
    }

    _webSocketService = webSocketService;

    // Écouter les signaux WebRTC entrants
    _webSocketService!.onCallSignalReceived = _handleIncomingSignal;

    // S'assurer que la souscription est active
    _webSocketService!.ensureCallSignalsSubscription();

    _isInitialized = true;
    print('WebRTCService initialized and listening for signals');
  }

  void _handleIncomingSignal(Map<String, dynamic> signal) async {
    try {
      final type = signal['type'];
      final data = signal['data'];

      print('WebRTCService received signal: $type');

      switch (type) {
        case 'offer':
          // Si on reçoit une offre, on doit avoir déjà un PeerConnection
          if (_peerConnection != null) {
            await handleOffer(data['sdp']);
          } else {
            print('Received offer but PeerConnection not ready');
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
    } catch (e) {
      print('Error handling incoming signal: $e');
    }
  }

  Future<void> startCall(String channelId, String remoteUserId) async {
    try {
      print('WebRTCService: Starting call to $remoteUserId on channel $channelId');
      _remoteUserId = remoteUserId;
      _currentCallId = channelId;

      await _createPeerConnection();
      await _createOffer();

      _callStateController.add(CallState.calling);
      print('WebRTCService: Call started, offer sent');
    } catch (e) {
      print('WebRTCService: Error starting call: $e');
      _callStateController.add(CallState.error);
      throw Exception('Failed to start call: $e');
    }
  }

  Future<void> answerCall(String channelId, String remoteUserId) async {
    try {
      print('WebRTCService: Answering call from $remoteUserId on channel $channelId');
      _remoteUserId = remoteUserId;
      _currentCallId = channelId;

      // Créer le PeerConnection et attendre
      await _createPeerConnection();

      // Ne pas marquer comme connecté immédiatement, attendre l'offre
      _callStateController.add(CallState.ringing);

      print('WebRTCService: PeerConnection ready to receive offer');
    } catch (e) {
      print('WebRTCService: Error answering call: $e');
      _callStateController.add(CallState.error);
      throw Exception('Failed to answer call: $e');
    }
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_configuration);

    _localStream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate != null) {
        _sendSignalingMessage('ice-candidate', {
          'candidate': candidate.toMap(),
        });
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStreamController.add(event.streams[0]);
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _callStateController.add(CallState.connected);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          _callStateController.add(CallState.ended);
          break;
        default:
          break;
      }
    };
  }

  Future<void> _createOffer() async {
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _sendSignalingMessage('offer', {
      'sdp': offer.toMap(),
    });
  }

  Future<void> handleOffer(Map<String, dynamic> offerData) async {
    print('WebRTCService: Handling offer');
    RTCSessionDescription offer = RTCSessionDescription(
      offerData['sdp'],
      offerData['type'],
    );

    await _peerConnection?.setRemoteDescription(offer);
    print('WebRTCService: Remote description set');

    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    print('WebRTCService: Answer created and set');

    _sendSignalingMessage('answer', {
      'sdp': answer.toMap(),
    });
    print('WebRTCService: Answer sent');
  }

  Future<void> handleAnswer(Map<String, dynamic> answerData) async {
    print('WebRTCService: Handling answer');
    RTCSessionDescription answer = RTCSessionDescription(
      answerData['sdp'],
      answerData['type'],
    );

    await _peerConnection?.setRemoteDescription(answer);
    print('WebRTCService: Answer set as remote description');
  }

  Future<void> handleIceCandidate(Map<String, dynamic> candidateData) async {
    print('WebRTCService: Handling ICE candidate');
    RTCIceCandidate candidate = RTCIceCandidate(
      candidateData['candidate'],
      candidateData['sdpMid'],
      candidateData['sdpMLineIndex'],
    );

    await _peerConnection?.addCandidate(candidate);
    print('WebRTCService: ICE candidate added');
  }

  void _sendSignalingMessage(String type, Map<String, dynamic> data) {
    if (_webSocketService != null && _remoteUserId != null) {
      _webSocketService!.sendCallSignal(
        type,
        _remoteUserId!,
        data,
        _currentCallId,
      );
    }
  }

  Future<void> toggleMute() async {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks().first;
      audioTrack.enabled = !audioTrack.enabled;
    }
  }

  bool get isMuted {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks().first;
      return !audioTrack.enabled;
    }
    return false;
  }

  Future<void> endCall() async {
    _sendSignalingMessage('end-call', {});
    await _cleanup();
    _callStateController.add(CallState.ended);
  }

  Future<void> _cleanup() async {
    try {
      if (_localStream != null) {
        for (var track in _localStream!.getTracks()) {
          await track.stop();
          track.dispose();
        }
        await _localStream!.dispose();
        _localStream = null;
      }

      if (_peerConnection != null) {
        await _peerConnection!.close();
        await _peerConnection!.dispose();
        _peerConnection = null;
      }

      _currentCallId = null;
      _remoteUserId = null;

      print('WebRTCService cleaned up and ready for next call');
    } catch (e) {
      print('Error during cleanup: $e');
      _localStream = null;
      _peerConnection = null;
      _currentCallId = null;
      _remoteUserId = null;
    }
  }

  // Getter pour vérifier si initialisé
  bool get isInitialized => _isInitialized;

  void dispose() {
    _cleanup();
    _remoteStreamController.close();
    _callStateController.close();
    _isInitialized = false;
    _webSocketService = null;
    print('WebRTCService fully disposed');
  }
}

enum CallState {
  idle,
  calling,
  ringing,
  connected,
  ended,
  error,
}
