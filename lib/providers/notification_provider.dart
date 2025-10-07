import 'package:flutter/material.dart';

class NotificationProvider with ChangeNotifier {
  int _unreadMessages = 0;
  int _newFiles = 0;
  List<String> _notifications = [];

  int get unreadMessages => _unreadMessages;
  int get newFiles => _newFiles;
  List<String> get notifications => _notifications;
  int get totalNotifications => _unreadMessages + _newFiles;

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
}