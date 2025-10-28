kipping messages load');
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
    final currentUser = StorageService.getUser();
    final senderId = currentUser?.email ?? 'unknown';
    print('DEBUG: Sending message from user email: $senderId');

    final tempId = -DateTime.now().millisecondsSinceEpoch;

    final tempMessage = Message(
      id: tempId,
      channelId: channelId,
      senderId: senderId,
      senderFname: currentUser?.firstName ?? '',
      senderLname: currentUser?.lastName ?? '',
      senderPicture: currentUser?.profilePicture,
      content: content,
      type: type,
      replyToId: replyToId,
      isEdited: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    final channelMessages = _channelMessages[channelId] ?? [];
    channelMessages.insert(0, tempMessage);
    _channelMessages[channelId] = channelMessages;
    notifyListeners();

    try {
      _wsService.sendMessage(channelId, content, type, replyToId: replyToId);
      print('DEBUG: Message sent via WebSocket, waiting for server confirmation');
    } catch (e) {
      print('DEBUG: Error sending message: $e');
      final updatedMessages = _channelMessages[channelId] ?? [];
      final tempMessageIndex = updatedMessages.indexWhere((m) => m.id == tempId);
      if (tempMessageIndex != -1) {
        updatedMessages[tempMessageIndex] = tempMessage.copyWith(
          status: MessageStatus.failed,
        );
        _channelMessages[channelId] = updatedMessages;
        notifyListeners();
      }
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
            senderFname: messages[messageIndex].senderFname,
            senderLname: messages[messageIndex].senderLname,
            senderPicture: messages[messageIndex].senderPicture,
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
            senderFname: messages[messageIndex].senderFname,
            senderLname: messages[messageIndex].senderLname,
            senderPicture: messages[messageIndex].senderPicture,
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
    final currentBuildingId = BuildingContextService().currentBuildingId;
    if (_currentBuildingContext != currentBuildingId) {
      print('DEBUG: Ignoring message - building context mismatch');
      return;
    }

    if (currentBuildingId == null) {
      print('DEBUG: No building context, ignoring message');
      return;
    }

    final currentUser = StorageService.getUser();
    print('DEBUG: Received message from: ${message.senderId}, current user ID: ${currentUser?.id}, current user email: ${currentUser?.email}');

    if (!_channelMessages.containsKey(message.channelId)) {
      print('DEBUG: Ignoring message for channel ${message.channelId} - not in current building context');
      return;
    }

    final channelMessages = _channelMessages[message.channelId] ?? [];

    final tempMessageIndex = channelMessages.indexWhere(
      (m) => m.id < 0 &&
             m.senderId == message.senderId &&
             m.content == message.content &&
             m.type == message.type
    );

    if (tempMessageIndex != -1) {
      print('DEBUG: Found temporary message at index $tempMessageIndex, updating status to sent with real ID: ${message.id}');
      final tempMessage = channelMessages[tempMessageIndex];
      channelMessages[tempMessageIndex] = tempMessage.copyWith(
        id: message.id,
        status: MessageStatus.sent,
        createdAt: message.createdAt,
      );
      print('DEBUG: Updated temporary message to sent status');
      _channelMessages[message.channelId] = channelMessages;
      notifyListeners();
      return;
    }

    if (!channelMessages.any((m) => m.id == message.id)) {
      channelMessages.insert(0, message);
      print('DEBUG: Added new message with ID: ${message.id}');
      _channelMessages[message.channelId] = channelMessages;
      notifyListeners();
    } else {
      print('DEBUG: Message with ID ${message.id} already exists, skipping');
    }
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