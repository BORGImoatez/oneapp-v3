import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../utils/constants.dart';
import '../models/message_model.dart';
import 'storage_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  StompClient? _stompClient;
  bool _isConnected = false;
  final Map<int, void Function()> _subscriptions = {};

  // Callbacks
  Function(Message)? onMessageReceived;
  Function(String, String, bool)? onTypingReceived;
  Function(Map<String, dynamic>)? onCallSignalReceived;
  Function(Map<String, dynamic>)? onIncomingCall;
  Function()? onConnected;
  Function()? onDisconnected;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    final token = await StorageService.getToken();
    if (token == null) return;

    _stompClient = StompClient(
      config: StompConfig(
        url: Constants.wsUrl,
        onConnect: _onConnect,
        onDisconnect: _onDisconnect,
        onStompError: _onError,
        onWebSocketError: _onWebSocketError,
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    _stompClient!.activate();
  }

  void _onConnect(StompFrame frame) {
    print('WebSocket connected');
    _isConnected = true;
    _subscribeToCallSignals();
    onConnected?.call();
  }

  // Permet de s'abonner aux signaux même si déjà connecté
  void ensureCallSignalsSubscription() {
    if (_isConnected) {
      _subscribeToCallSignals();
    }
  }

  void _onDisconnect(StompFrame frame) {
    print('WebSocket disconnected');
    _isConnected = false;
    onDisconnected?.call();
  }

  void _onError(StompFrame frame) {
    print('WebSocket STOMP error: ${frame.body}');
  }

  void _onWebSocketError(dynamic error) {
    print('WebSocket error: $error');
  }

  void subscribeToChannel(int channelId) {
    if (!_isConnected || _stompClient == null) return;

    // Unsubscribe from existing subscriptions for this channel
    unsubscribeFromChannel(channelId);

    // Subscribe to messages
    final messageSubscription = _stompClient!.subscribe(
      destination: '/topic/channel/$channelId',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final messageData = jsonDecode(frame.body!);
            final message = Message.fromJson(messageData);
            onMessageReceived?.call(message);
          } catch (e) {
            print('Error parsing message: $e');
          }
        }
      },
    );

    // Subscribe to typing indicators
    final typingSubscription = _stompClient!.subscribe(
      destination: '/topic/channel/$channelId/typing',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final typingData = jsonDecode(frame.body!);
            onTypingReceived?.call(
              typingData['userId'],
              typingData['channelId'].toString(),
              typingData['isTyping'],
            );
          } catch (e) {
            print('Error parsing typing indicator: $e');
          }
        }
      },
    );

    // Store unsubscribe functions
    _subscriptions[channelId] = () {
      messageSubscription();
      typingSubscription();
    };
  }

  void unsubscribeFromChannel(int channelId) {
    final unsubscribe = _subscriptions[channelId];
    if (unsubscribe != null) {
      unsubscribe();
      _subscriptions.remove(channelId);
    }
  }

  void sendMessage(int channelId, String content, String type, {int? replyToId}) {
    if (!_isConnected || _stompClient == null) return;

    final messageData = {
      'channelId': channelId,
      'content': content,
      'type': type,
      if (replyToId != null) 'replyToId': replyToId,
    };

    _stompClient!.send(
      destination: '/app/message.send',
      body: jsonEncode(messageData),
    );
  }

  void sendTypingIndicator(int channelId, bool isTyping) {
    if (!_isConnected || _stompClient == null) return;

    final typingData = {
      'channelId': channelId,
      'isTyping': isTyping,
    };

    _stompClient!.send(
      destination: '/app/message.typing',
      body: jsonEncode(typingData),
    );
  }

  void disconnect() {
    // Unsubscribe from all channels
    for (final unsubscribe in _subscriptions.values) {
      unsubscribe();
    }
    _subscriptions.clear();

    if (_stompClient != null) {
      _stompClient!.deactivate();
      _stompClient = null;
    }
    _isConnected = false;
    print('DEBUG: WebSocket disconnected and all subscriptions cleared');
  }

  void clearAllSubscriptions() {
    // Nettoyer toutes les souscriptions sans déconnecter
    try {
      final subscriptionIds = List<int>.from(_subscriptions.keys);
      for (final channelId in subscriptionIds) {
        final unsubscribe = _subscriptions[channelId];
        if (unsubscribe != null) {
          unsubscribe();
        }
      }
      _subscriptions.clear();
      print('DEBUG: All WebSocket subscriptions cleared (${subscriptionIds.length} channels)');
    } catch (e) {
      print('DEBUG: Error clearing WebSocket subscriptions: $e');
      _subscriptions.clear();
    }
  }

  void _subscribeToCallSignals() {
    if (!_isConnected || _stompClient == null) return;

    // Subscribe to WebRTC signaling messages
    _stompClient!.subscribe(
      destination: '/user/queue/signal',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final signalData = jsonDecode(frame.body!);
            print('Received call signal: ${signalData['type']}');
            onCallSignalReceived?.call(signalData);
          } catch (e) {
            print('Error parsing call signal: $e');
          }
        }
      },
    );

    // Subscribe to call notifications (incoming calls, call status updates)
    _stompClient!.subscribe(
      destination: '/user/queue/call',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final callData = jsonDecode(frame.body!);
            print('Received call notification: ${callData['status']}');
            onIncomingCall?.call(callData);
          } catch (e) {
            print('Error parsing call notification: $e');
          }
        }
      },
    );
  }

  void sendCallSignal(String type, String to, Map<String, dynamic> data, String? channelId) {
    if (!_isConnected || _stompClient == null) return;

    final signalData = {
      'type': type,
      'to': to,
      'data': data,
      if (channelId != null) 'channelId': channelId,
    };

    print('Sending call signal: $type to $to');
    _stompClient!.send(
      destination: '/app/call.signal',
      body: jsonEncode(signalData),
    );
  }

  StompClient? get stompClient => _stompClient;
}