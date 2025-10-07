import 'dart:io';

import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../services/storage_service.dart';
import '../services/building_context_service.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final WebSocketService _wsService = WebSocketService();

  final Map<int, List<Message>> _channelMessages = {};
  final Map<int, bool> _isLoadingMessages = {};
  final Map<String, bool> _typingUsers = {};
  String? _currentBuildingContext;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  ChatProvider() {
    _wsService.onMessageReceived = _handleNewMessage;
    _wsService.onTypingReceived = _handleTypingIndicator;
  }

  List<Message> getChannelMessages(int channelId) {
    // Vérifier le contexte du bâtiment
    final currentBuildingId = BuildingContextService().currentBuildingId;
    if (_currentBuildingContext != currentBuildingId) {
      print('DEBUG: Building context changed, clearing messages data');
      _channelMessages.clear();
      _isLoadingMessages.clear();
      _typingUsers.clear();
      _currentBuildingContext = currentBuildingId;
      notifyListeners();
      return [];
    }

    return _channelMessages[channelId] ?? [];
  }

  bool isLoadingMessages(int channelId) {
    return _isLoadingMessages[channelId] ?? false;
  }

  List<String> getTypingUsers(int channelId) {
    return _typingUsers.entries
        .where((entry) => entry.key.startsWith('$channelId:') && entry.value)
        .map((entry) => entry.key.split(':')[1])
        .toList();
  }

  Future<void> loadChannelMessages(int channelId, {bool refresh = false}) async {
    if (_isLoadingMessages[channelId] == true) return;

    // Vérifier le contexte du bâtiment
    final currentBuildingId = BuildingContextService().currentBuildingId;
    if (_currentBuildingContext != currentBuildingId || refresh) {
      print('DEBUG: Building context changed, clearing messages before loading');
      _channelMessages.clear();
      _isLoadingMessages.clear();
      _typingUsers.clear();
      _currentBuildingContext = currentBuildingId;
    }

    // Ne pas charger si pas de contexte de bâtiment
    if (currentBuildingId == null) {
      print('DEBUG: No building context, skipping messages load');
      return;
    }

    _isLoadingMessages[channelId] = true;
    notifyListeners();

    try {
      print('DEBUG: Loading messages for channel $channelId in building: $currentBuildingId');
      final response = await _apiService.getChannelMessages(channelId);
      final messages = (response['content'] as List)
          .map((json) => Message.fromJson(json))
          .toList();

      // Debug log pour vérifier les messages chargés
      final currentUser = StorageService.getUser();
      final currentUserId = currentUser?.id ?? 'unknown';
      print('DEBUG: Loaded ${messages.length} messages for channel $channelId');
      print('DEBUG: Current user ID: $currentUserId');
      if (messages.isNotEmpty) {
        print('DEBUG: First message from: ${messages.first.senderId}');
      }
      if (refresh) {
        _channelMessages[channelId] = messages;
      } else {
        _channelMessages[channelId] = [
          ...(_channelMessages[channelId] ?? []),
          ...messages,
        ];
      }

      // Subscribe to WebSocket for this channel
      _wsService.subscribeToChannel(channelId);

    } catch (e) {
      _setError(e.toString());
    } finally {
      _isLoadingMessages[channelId] = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(int channelId, String content, String type, {int? replyToId}) async {
    await _sendMessageInternal(channelId, content, type, replyToId: replyToId);
  }

  Future<void> sendMessageWithFile(int channelId, File file, String type, {int? replyToId}) async {
    try {
      // Upload file first
      final uploadResult = await _apiService.uploadFile(file, type);
      String fileUrl = uploadResult['url'];
      final fileName = uploadResult['originalName'] ?? file.path.split('/').last;

      // For images, ensure the URL has the correct prefix
      if (type == 'IMAGE' && !fileUrl.startsWith('http')) {
        fileUrl = 'http://192.168.1.5:9090/api/v1/files/$fileUrl';
      }

      // Send message with file URL
      await _sendMessageInternal(channelId, fileUrl, type, replyToId: replyToId);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> _sendMessageInternal(int channelId, String content, String type, {int? replyToId}) async {
    // Récupérer l'ID de l'utilisateur actuel
    final currentUser = StorageService.getUser();
    // Utiliser l'email comme senderId pour être cohérent avec le backend
    final senderId = currentUser?.email ?? 'unknown';
    print('DEBUG: Sending message from user email: $senderId'); // Debug log

    try {
      // Envoyer uniquement via WebSocket - le message sera reçu via WebSocket
      _wsService.sendMessage(channelId, content, type, replyToId: replyToId);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> editMessage(int messageId, String newContent) async {
    try {
      await _apiService.editMessage(messageId, newContent);

      // Update local message
      for (final messages in _channelMessages.values) {
        final messageIndex = messages.indexWhere((m) => m.id == messageId);
        if (messageIndex != -1) {
          final updatedMessage = Message(
            id: messages[messageIndex].id,
            channelId: messages[messageIndex].channelId,
            senderId: messages[messageIndex].senderId,
            content: newContent,
            type: messages[messageIndex].type,
            replyToId: messages[messageIndex].replyToId,
            isEdited: true,
            isDeleted: messages[messageIndex].isDeleted,
            createdAt: messages[messageIndex].createdAt,
            updatedAt: DateTime.now(),
          );
          messages[messageIndex] = updatedMessage;
          break;
        }
      }
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      await _apiService.deleteMessage(messageId);

      // Update local message
      for (final messages in _channelMessages.values) {
        final messageIndex = messages.indexWhere((m) => m.id == messageId);
        if (messageIndex != -1) {
          final updatedMessage = Message(
            id: messages[messageIndex].id,
            channelId: messages[messageIndex].channelId,
            senderId: messages[messageIndex].senderId,
            content: '[Message supprimé]',
            type: messages[messageIndex].type,
            replyToId: messages[messageIndex].replyToId,
            isEdited: messages[messageIndex].isEdited,
            isDeleted: true,
            createdAt: messages[messageIndex].createdAt,
            updatedAt: DateTime.now(),
          );
          messages[messageIndex] = updatedMessage;
          break;
        }
      }
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void sendTypingIndicator(int channelId, bool isTyping) {
    _wsService.sendTypingIndicator(channelId, isTyping);
  }

  void _handleNewMessage(Message message) {
    // Vérifier le contexte du bâtiment
    final currentBuildingId = BuildingContextService().currentBuildingId;
    if (_currentBuildingContext != currentBuildingId) {
      print('DEBUG: Ignoring message - building context mismatch');
      return;
    }

    // Vérifier que le message appartient au bâtiment actuel
    // Cette vérification sera faite côté serveur, mais on peut ajouter une sécurité côté client
    if (currentBuildingId == null) {
      print('DEBUG: No building context, ignoring message');
      return;
    }

    final currentUser = StorageService.getUser();
    print('DEBUG: Received message from: ${message.senderId}, current user ID: ${currentUser?.id}, current user email: ${currentUser?.email}'); // Debug log

    // Vérifier que le message appartient à un canal de l'utilisateur actuel
    if (!_channelMessages.containsKey(message.channelId)) {
      print('DEBUG: Ignoring message for channel ${message.channelId} - not in current building context');
      return;
    }

    final channelMessages = _channelMessages[message.channelId] ?? [];

    // Ajouter le nouveau message s'il n'existe pas déjà
    if (!channelMessages.any((m) => m.id == message.id)) {
      channelMessages.insert(0, message);
      print('DEBUG: Added new message with ID: ${message.id}'); // Debug log
    } else {
      print('DEBUG: Message with ID ${message.id} already exists, skipping'); // Debug log
    }

    _channelMessages[message.channelId] = channelMessages;
    notifyListeners();
  }

  void _handleTypingIndicator(String userId, String channelId, bool isTyping) {
    final key = '$channelId:$userId';
    _typingUsers[key] = isTyping;

    // Remove typing indicator after 3 seconds
    if (isTyping) {
      Future.delayed(const Duration(seconds: 3), () {
        _typingUsers[key] = false;
        notifyListeners();
      });
    }

    notifyListeners();
  }

  void clearChannelMessages(int channelId) {
    _channelMessages.remove(channelId);
    _wsService.unsubscribeFromChannel(channelId);
    notifyListeners();
  }

  void clearAllData() {
    _channelMessages.clear();
    _isLoadingMessages.clear();
    _typingUsers.clear();
    _isLoading = false;
    _error = null;
    _currentBuildingContext = null;

    // Déconnecter de tous les canaux WebSocket
    final channelIds = List<int>.from(_channelMessages.keys);
    for (final channelId in channelIds) {
      _wsService.unsubscribeFromChannel(channelId);
    }

    // Nettoyer toutes les souscriptions WebSocket
    _wsService.clearAllSubscriptions();

    notifyListeners();
  }

  void forceRefreshForBuilding(String buildingId) {
    print('DEBUG: Force refreshing chat data for building: $buildingId');

    // Nettoyer toutes les données
    final channelIds = List<int>.from(_channelMessages.keys);
    for (final channelId in channelIds) {
      _wsService.unsubscribeFromChannel(channelId);
    }

    _channelMessages.clear();
    _isLoadingMessages.clear();
    _typingUsers.clear();
    _currentBuildingContext = buildingId;

    notifyListeners();
  }
  void clearMessagesForBuilding() {
    // Nettoyer tous les messages et déconnecter les WebSockets
    for (final channelId in _channelMessages.keys) {
      _wsService.unsubscribeFromChannel(channelId);
    }
    _channelMessages.clear();
    _isLoadingMessages.clear();
    _typingUsers.clear();
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}