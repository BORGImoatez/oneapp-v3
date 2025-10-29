import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'storage_service.dart';

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

  StompClient? _stompClient;
  String? _currentCallId;
  String? _remoteUserId;

  Future<void> initialize(StompClient stompClient) async {
    _stompClient = stompClient;
  }

  Future<void> startCall(String channelId, String remoteUserId) async {
    try {
      _remoteUserId = remoteUserId;
      _currentCallId = channelId;

      await _createPeerConnection();
      await _createOffer();

      _callStateController.add(CallState.calling);
    } catch (e) {
      _callStateController.add(CallState.error);
      throw Exception('Failed to start call: $e');
    }
  }

  Future<void> answerCall(String channelId, String remoteUserId) async {
    try {
      _remoteUserId = remoteUserId;
      _currentCallId = channelId;

      await _createPeerConnection();
      _callStateController.add(CallState.connected);
    } catch (e) {
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
    RTCSessionDescription offer = RTCSessionDescription(
      offerData['sdp'],
      offerData['type'],
    );

    await _peerConnection?.setRemoteDescription(offer);

    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _sendSignalingMessage('answer', {
      'sdp': answer.toMap(),
    });
  }

  Future<void> handleAnswer(Map<String, dynamic> answerData) async {
    RTCSessionDescription answer = RTCSessionDescription(
      answerData['sdp'],
      answerData['type'],
    );

    await _peerConnection?.setRemoteDescription(answer);
  }

  Future<void> handleIceCandidate(Map<String, dynamic> candidateData) async {
    RTCIceCandidate candidate = RTCIceCandidate(
      candidateData['candidate'],
      candidateData['sdpMid'],
      candidateData['sdpMLineIndex'],
    );

    await _peerConnection?.addCandidate(candidate);
  }

  void _sendSignalingMessage(String type, Map<String, dynamic> data) {
    if (_stompClient != null && _remoteUserId != null) {
      _stompClient!.send(
        destination: '/app/call.signal',
        body: {
          'type': type,
          'channelId': _currentCallId,
          'to': _remoteUserId,
          'data': data,
        }.toString(),
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
    await _localStream?.dispose();
    await _peerConnection?.close();
    _localStream = null;
    _peerConnection = null;
    _currentCallId = null;
    _remoteUserId = null;
  }

  void dispose() {
    _cleanup();
    _remoteStreamController.close();
    _callStateController.close();
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
