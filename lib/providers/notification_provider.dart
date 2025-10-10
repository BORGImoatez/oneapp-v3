import 'package:flutter/material.dart';
import '../services/notification_api_service.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  int _unreadMessages = 0;
  int _newFiles = 0;
  int _unreadNotifications = 0;
  List<String> _notifications = [];
  final NotificationApiService _notificationService = NotificationApiService(ApiService());

  int get unreadMessages => _unreadMessages;
  int get newFiles => _newFiles;
  int get unreadNotifications => _unreadNotifications;
  List<String> get notifications => _notifications;
  int get totalNotifications => _unreadNotifications;

  void incrementUnreadMessages() {
    _unreadMessages++;
    notifyListeners();
  }

  void clearUnreadMessages() {
    _unreadMessages = 0;
    notifyListeners();
  }

  void incrementNewFiles() {
    _newFiles++;
    _notifications.add('Nouveau fichier disponible');
    notifyListeners();
  }

  void clearNewFiles() {
    _newFiles = 0;
    notifyListeners();
  }

  void addNotification(String notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void removeNotification(int index) {
    if (index < _notifications.length) {
      _notifications.removeAt(index);
      notifyListeners();
    }
  }

  void clearAllNotifications() {
    _notifications.clear();
    _unreadMessages = 0;
    _newFiles = 0;
    notifyListeners();
  }

  Future<void> loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      _unreadNotifications = count;
      notifyListeners();
    } catch (e) {
      print('Error loading unread notification count: $e');
    }
  }

  Future<void> loadUnreadCountForBuilding(String buildingId) async {
    try {
      final count = await _notificationService.getUnreadCountByBuilding(buildingId);
      _unreadNotifications = count;
      notifyListeners();
    } catch (e) {
      print('Error loading unread notification count for building: $e');
    }
  }

  void incrementUnreadNotifications() {
    _unreadNotifications++;
    notifyListeners();
  }

  void clearUnreadNotifications() {
    _unreadNotifications = 0;
    notifyListeners();
  }
}