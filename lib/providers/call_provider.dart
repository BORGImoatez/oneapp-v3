import 'package:flutter/foundation.dart';
import '../models/call_model.dart';
import '../services/call_service.dart';
import '../services/webrtc_service.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class CallProvider with ChangeNotifier {
  final CallService _callService = CallService();
  final WebRTCService _webrtcService = WebRTCService();

  CallModel? _currentCall;
  bool _isInCall = false;
  List<CallModel> _callHistory = [];

  CallModel? get currentCall => _currentCall;
  bool get isInCall => _isInCall;
  List<CallModel> get callHistory => _callHistory;
  WebRTCService get webrtcService => _webrtcService;

  void initialize(StompClient stompClient) {
    _webrtcService.initialize(stompClient);
  }

  Future<void> initiateCall({
    required int channelId,
    required String receiverId,
  }) async {
    try {
      final call = await _callService.initiateCall(
        channelId: channelId,
        receiverId: receiverId,
      );

      _currentCall = call;
      _isInCall = true;

      await _webrtcService.startCall(
        channelId.toString(),
        receiverId,
      );

      notifyListeners();
    } catch (e) {
      print('Error initiating call: $e');
      rethrow;
    }
  }

  Future<void> answerCall(CallModel call) async {
    try {
      final updatedCall = await _callService.answerCall(call.id!);

      _currentCall = updatedCall;
      _isInCall = true;

      await _webrtcService.answerCall(
        call.channelId.toString(),
        call.callerId,
      );

      notifyListeners();
    } catch (e) {
      print('Error answering call: $e');
      rethrow;
    }
  }

  Future<void> endCall() async {
    if (_currentCall == null) return;

    try {
      await _callService.endCall(_currentCall!.id!);
      await _webrtcService.endCall();

      _currentCall = null;
      _isInCall = false;

      notifyListeners();
    } catch (e) {
      print('Error ending call: $e');
      _currentCall = null;
      _isInCall = false;
      notifyListeners();
    }
  }

  Future<void> rejectCall(CallModel call) async {
    try {
      await _callService.rejectCall(call.id!);

      if (_currentCall?.id == call.id) {
        _currentCall = null;
        _isInCall = false;
      }

      notifyListeners();
    } catch (e) {
      print('Error rejecting call: $e');
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
    _webrtcService.dispose();
    super.dispose();
  }
}
