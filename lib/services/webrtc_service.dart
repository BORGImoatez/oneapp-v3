import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

import 'package:mgi/services/storage_service.dart';
import 'package:mgi/utils/constants.dart';
import 'websocket_service.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  final _remoteStreamController = StreamController<MediaStream>.broadcast();
  final _callStateController = StreamController<CallState>.broadcast();

  Stream<MediaStream> get remoteStream => _remoteStreamController.stream;
  Stream<CallState> get callState => _callStateController.stream;

  Map<String, dynamic>? _configuration;

  /// ⚙️ Contraintes simples et compatibles (audio only)
  final Map<String, dynamic> _mediaConstraints = {
    'audio': true,
    'video': false,
  };

  final Map<String, dynamic> _offerConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': false,
    },
    'optional': [],
  };

  WebSocketService? _webSocketService;
  String? _currentCallId;
  String? _remoteUserId;

  bool _isInitialized = false;
  bool _makingOffer = false;

  /// Gestion du “premier appel qui ne marche pas”
  final List<_PendingSignal> _pendingSignals = [];
  bool _peerConnectionReady = false;
  Completer<void>? _peerConnectionReadyCompleter;

  final List<Map<String, dynamic>> _pendingRemoteIceCandidates = [];
  bool _remoteDescriptionSet = false;

  Timer? _iceCandidateTimer;
  final List<Map<String, dynamic>> _localIceCandidatesToSend = [];

  // -------------------------
  // INITIALISATION
  // -------------------------
  Future<void> initialize(WebSocketService webSocketService) async {
    if (_isInitialized) return;

    _webSocketService = webSocketService;
    _webSocketService!.onCallSignalReceived = _handleIncomingSignal;
    _webSocketService!.ensureCallSignalsSubscription();

    _isInitialized = true;
    print('✅ WebRTCService initialized');
  }

  // -------------------------
  // TURN / STUN DYNAMIQUE
  // -------------------------
  Future<Map<String, dynamic>> _getTurnConfiguration() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        print('⚠️ No token, using fallback STUN only');
        return {
          'iceServers': [
            {'urls': 'stun:51.91.99.191:3478'}
          ],
        };
      }

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/webrtc/turn-credentials'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ TURN credentials loaded: ${data['username']}');

        return {
          'iceServers': [
            {
              'urls': data['uris'], // la liste d’URL retournée par ton backend
              'username': data['username'],
              'credential': data['password'],
            }
          ],
        };
      } else {
        print('❌ Failed to load TURN: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception while loading TURN credentials: $e');
    }

    // Fallback STUN
    return {
      'iceServers': [
        {'urls': 'stun:51.91.99.191:3478'}
      ],
    };
  }

  // -------------------------
  // DÉMARRER UN APPEL (CALLER)
  // -------------------------
  Future<void> startCall(String channelId, String remoteUserId) async {
    try {
      await _cleanup();

      _remoteUserId = remoteUserId;
      _currentCallId = channelId;

      _remoteDescriptionSet = false;
      _pendingRemoteIceCandidates.clear();
      _pendingSignals.clear();
      _peerConnectionReady = false;
      _peerConnectionReadyCompleter = Completer<void>();

      final iceConfig = await _getTurnConfiguration();

      _configuration = {
        ...iceConfig,
        'sdpSemantics': 'unified-plan',
        'iceTransportPolicy': 'all',
        'bundlePolicy': 'max-bundle',
        'rtcpMuxPolicy': 'require',
        'iceCandidatePoolSize': 10,
      };

      print('📦 startCall final config: ${jsonEncode(_configuration)}');

      await _createPeerConnection();

      _peerConnectionReady = true;
      _peerConnectionReadyCompleter?.complete();
      await _processPendingSignals();

      await _createOffer();
      _callStateController.add(CallState.calling);
    } catch (e) {
      print('❌ Error starting call: $e');
      _callStateController.add(CallState.error);
      rethrow;
    }
  }

  // -------------------------
  // RÉPONDRE À UN APPEL (CALLEE)
  // -------------------------
  Future<void> answerCall(String channelId, String remoteUserId) async {
    try {
      await _cleanup();

      _remoteUserId = remoteUserId;
      _currentCallId = channelId;

      _remoteDescriptionSet = false;
      _pendingRemoteIceCandidates.clear();
      _pendingSignals.clear();
      _peerConnectionReady = false;
      _peerConnectionReadyCompleter = Completer<void>();

      // ⚠️ IMPORTANT :
      // la permission micro doit être demandée côté UI AVANT d’arriver ici.

      final iceConfig = await _getTurnConfiguration();

      _configuration = {
        ...iceConfig,
        'sdpSemantics': 'unified-plan',
        'iceTransportPolicy': 'all',
        'bundlePolicy': 'max-bundle',
        'rtcpMuxPolicy': 'require',
        'iceCandidatePoolSize': 10,
      };

      print('📦 answerCall config: ${jsonEncode(_configuration)}');

      await _createPeerConnection();

      _peerConnectionReady = true;
      _peerConnectionReadyCompleter?.complete();
      _callStateController.add(CallState.ringing);

      await _processPendingSignals();
    } catch (e) {
      print('❌ Error answering call: $e');
      _callStateController.add(CallState.error);
      rethrow;
    }
  }

  // -------------------------
  // CRÉATION PEERCONNECTION
  // -------------------------
  Future<void> _createPeerConnection() async {
    try {
      print('🧩 Creating PeerConnection with config: ${jsonEncode(_configuration)}');

      _peerConnection = await createPeerConnection(_configuration!);

      // 🎤 Initialiser le micro UNE SEULE FOIS
      _localStream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);

      final audioTracks = _localStream!.getAudioTracks();
      print('🎙 Local audio tracks count: ${audioTracks.length}');
      for (var t in audioTracks) {
        print('   -> id=${t.id}, enabled=${t.enabled}, muted=${t.muted}');
      }

      for (var track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }

      // ICE CANDIDATES (batching)
      _peerConnection!.onIceCandidate = (candidate) {
        if (candidate.candidate == null) return;

        final type = candidate.candidate!.contains('typ relay')
            ? 'relay (TURN)'
            : candidate.candidate!.contains('typ srflx')
            ? 'srflx (STUN)'
            : 'host';

        print('❄ ICE [$type]: ${candidate.candidate!.substring(0, 80)}...');

        _localIceCandidatesToSend.add(candidate.toMap());
        _iceCandidateTimer?.cancel();
        _iceCandidateTimer =
            Timer(const Duration(milliseconds: 80), _sendBatchedIceCandidates);
      };

      _peerConnection!.onIceGatheringState = (state) {
        print('❄ ICE Gathering: $state');
        if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
          _sendBatchedIceCandidates();
        }
      };

      _peerConnection!.onIceConnectionState = (state) {
        print('❄ ICE Connection: $state');
        if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          print('❌ ICE failed - check TURN / réseau');
          _callStateController.add(CallState.error);
        } else if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
          print('✅ ICE connected');
        }
      };

      _peerConnection!.onTrack = (event) {
        if (event.streams.isNotEmpty) {
          print('📡 Remote track received');
          _remoteStreamController.add(event.streams[0]);
        }
      };

      _peerConnection!.onConnectionState = (state) {
        print('🌐 Connection: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _callStateController.add(CallState.connected);
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _callStateController.add(CallState.error);
        }
      };
    } catch (e) {
      print('❌ Error creating PeerConnection: $e');
      rethrow;
    }
  }

  // -------------------------
  // ENVOI DES ICE CANDIDATES
  // -------------------------
  void _sendBatchedIceCandidates() {
    if (_localIceCandidatesToSend.isEmpty) return;
    print('📨 Sending ${_localIceCandidatesToSend.length} ICE candidates');
    for (var c in _localIceCandidatesToSend) {
      _sendSignalingMessage('ice-candidate', {'candidate': c});
    }
    _localIceCandidatesToSend.clear();
  }

  // -------------------------
  // OFFRE (CALLER)
  // -------------------------
  Future<void> _createOffer() async {
    _makingOffer = true;
    final offer = await _peerConnection!.createOffer(_offerConstraints);
    await _peerConnection!.setLocalDescription(offer);
    _sendSignalingMessage('offer', {'sdp': offer.toMap()});
    _makingOffer = false;
  }

  // -------------------------
  // HANDLE OFFER (CALLEE)
  // -------------------------
  Future<void> handleOffer(Map<String, dynamic> data) async {
    try {
      print('📨 handleOffer: keys=${data.keys}');

      String sdpString;
      String typeString;

      if (data['sdp'] is Map) {
        final sdpMap = data['sdp'] as Map<String, dynamic>;
        sdpString = sdpMap['sdp']?.toString() ?? '';
        typeString = sdpMap['type']?.toString() ?? 'offer';
        print('   SDP extracted from Map');
      } else {
        sdpString = data['sdp']?.toString() ?? '';
        typeString = data['type']?.toString() ?? 'offer';
        print('   SDP is already String');
      }

      print('   SDP type: $typeString, length: ${sdpString.length}');

      if (sdpString.isEmpty) {
        throw Exception('Empty SDP received in offer');
      }

      final offer = RTCSessionDescription(sdpString, typeString);

      final collision = _makingOffer ||
          _peerConnection!.signalingState !=
              RTCSignalingState.RTCSignalingStateStable;

      if (collision) {
        print('⚠️ Signaling collision detected, ignoring offer');
        return;
      }

      await _peerConnection!.setRemoteDescription(offer);
      _remoteDescriptionSet = true;

      // Ajouter les ICE candidates en attente
      for (var c in _pendingRemoteIceCandidates) {
        await _addIceCandidate(c);
      }
      _pendingRemoteIceCandidates.clear();

      final answer = await _peerConnection!.createAnswer(_offerConstraints);
      await _peerConnection!.setLocalDescription(answer);
      _sendSignalingMessage('answer', {'sdp': answer.toMap()});
    } catch (e, stackTrace) {
      print('❌ Error in handleOffer: $e');
      print(stackTrace);
      print('Data received: $data');
      rethrow;
    }
  }

  // -------------------------
  // HANDLE ANSWER (CALLER)
  // -------------------------
  Future<void> handleAnswer(Map<String, dynamic> data) async {
    try {
      print('📨 handleAnswer: keys=${data.keys}');

      String sdpString;
      String typeString;

      if (data['sdp'] is Map) {
        final sdpMap = data['sdp'] as Map<String, dynamic>;
        sdpString = sdpMap['sdp']?.toString() ?? '';
        typeString = sdpMap['type']?.toString() ?? 'answer';
        print('   Answer SDP extracted from Map');
      } else {
        sdpString = data['sdp']?.toString() ?? '';
        typeString = data['type']?.toString() ?? 'answer';
        print('   Answer SDP is already String');
      }

      if (sdpString.isEmpty) {
        throw Exception('Empty SDP in answer');
      }

      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(sdpString, typeString),
      );
      _remoteDescriptionSet = true;

      for (var c in _pendingRemoteIceCandidates) {
        await _addIceCandidate(c);
      }
      _pendingRemoteIceCandidates.clear();
    } catch (e) {
      print('❌ Error in handleAnswer: $e');
      rethrow;
    }
  }

  // -------------------------
  // HANDLE ICE CANDIDATE (BOTH SIDES)
  // -------------------------
  Future<void> handleIceCandidate(Map<String, dynamic> data) async {
    // selon ton backend, le candidate peut être dans data['candidate'] ou à plat
    final candidateData = (data['candidate'] is Map)
        ? (data['candidate'] as Map<String, dynamic>)
        : data;

    if (!_remoteDescriptionSet) {
      print('⏳ Remote SDP not set yet → queue ICE');
      _pendingRemoteIceCandidates.add(candidateData);
    } else {
      await _addIceCandidate(candidateData);
    }
  }

  Future<void> _addIceCandidate(Map<String, dynamic> data) async {
    try {
      final candidate = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );
      await _peerConnection?.addCandidate(candidate);
      print('✅ ICE candidate added');
    } catch (e) {
      print('❌ Error adding ICE candidate: $e');
    }
  }

  // -------------------------
  // SIGNALISATION
  // -------------------------
  void _sendSignalingMessage(String type, Map<String, dynamic> data) {
    if (_remoteUserId == null || _currentCallId == null) {
      print('⚠️ Cannot send signaling message, no remoteUserId/callId');
      return;
    }
    _webSocketService?.sendCallSignal(
      type,
      _remoteUserId!,
      data,
      _currentCallId,
    );
  }

  // -------------------------
  // MUTE / UNMUTE MICRO
  // -------------------------
  Future<void> toggleMute() async {
    if (_localStream == null) return;
    final tracks = _localStream!.getAudioTracks();
    if (tracks.isEmpty) return;

    final current = tracks.first.enabled;
    final newValue = !current;

    for (var t in tracks) {
      t.enabled = newValue;
    }

    print(newValue ? '🎙️ Micro activé' : '🔇 Micro désactivé');
  }

  bool get isMuted {
    if (_localStream == null) return false;
    final tracks = _localStream!.getAudioTracks();
    if (tracks.isEmpty) return false;
    return tracks.first.enabled == false;
  }

  // -------------------------
  // FIN D'APPEL
  // -------------------------
  Future<void> endCall() async {
    _sendSignalingMessage('end-call', {});
    await _cleanup();
    _callStateController.add(CallState.ended);
  }

  // -------------------------
  // CLEANUP
  // -------------------------
  Future<void> _cleanup() async {
    print('🧹 Cleaning up WebRTCService...');

    _iceCandidateTimer?.cancel();

    _localStream?.getTracks().forEach((t) => t.stop());
    await _localStream?.dispose();

    await _peerConnection?.close();
    await _peerConnection?.dispose();

    _localStream = null;
    _peerConnection = null;
    _currentCallId = null;
    _remoteUserId = null;

    _pendingSignals.clear();
    _pendingRemoteIceCandidates.clear();
    _localIceCandidatesToSend.clear();

    _remoteDescriptionSet = false;
    _peerConnectionReady = false;
    _peerConnectionReadyCompleter = null;

    print('✅ WebRTCService cleanup done');
  }

  // -------------------------
  // GESTION DES SIGNAUX ENTRANTS
  // -------------------------
  void _handleIncomingSignal(Map<String, dynamic> signal) async {
    final type = signal['type'];
    final data = (signal['data'] ?? {}) as Map<String, dynamic>;

    print('📨 Incoming signal: $type');

    if (!_peerConnectionReady && type != 'end-call') {
      print('⏳ PeerConnection not ready → queue signal $type');
      _pendingSignals.add(_PendingSignal(type, data));
      return;
    }

    await _processSignal(type, data);
  }

  Future<void> _processSignal(String type, Map<String, dynamic> data) async {
    switch (type) {
      case 'offer':
        await handleOffer(data);
        break;
      case 'answer':
        await handleAnswer(data);
        break;
      case 'ice-candidate':
        await handleIceCandidate(data);
        break;
      case 'end-call':
        await endCall();
        break;
      default:
        print('⚠️ Unknown signal type: $type');
    }
  }

  Future<void> _processPendingSignals() async {
    if (_peerConnectionReadyCompleter != null) {
      await _peerConnectionReadyCompleter!.future;
    }

    for (var s in List<_PendingSignal>.from(_pendingSignals)) {
      print('📨 Processing queued signal: ${s.type}');
      await _processSignal(s.type, s.data);
    }
    _pendingSignals.clear();
  }

  // -------------------------
  // DISPOSE (service)
  // -------------------------
  void dispose() {
    _cleanup();
    _remoteStreamController.close();
    _callStateController.close();
    _isInitialized = false;
  }
}

enum CallState { idle, calling, ringing, connected, ended, error }

class _PendingSignal {
  final String type;
  final Map<String, dynamic> data;
  _PendingSignal(this.type, this.data);
}
