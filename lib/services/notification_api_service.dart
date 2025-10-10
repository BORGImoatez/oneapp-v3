import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationApiService {
  final ApiService _apiService;

  NotificationApiService(this._apiService);

  Future<List<NotificationModel>> getMyNotifications() async {
    try {
      final response = await _apiService.get('/notifications');
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      print('Error getting notifications: $e');
      rethrow;
    }
  }

  Future<List<NotificationModel>> getNotificationsByBuilding(String buildingId) async {
    try {
      final response = await _apiService.get('/notifications/building/$buildingId');
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      print('Error getting notifications by building: $e');
      rethrow;
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get('/notifications/unread-count');
      final data = json.decode(response.body);
      return data['unreadCount'] as int;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  Future<int> getUnreadCountByBuilding(String buildingId) async {
    try {
      final response = await _apiService.get('/notifications/unread-count/building/$buildingId');
      final data = json.decode(response.body);
      return data['unreadCount'] as int;
    } catch (e) {
      print('Error getting unread count by building: $e');
      return 0;
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await _apiService.put('/notifications/$notificationId/mark-read', {});
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiService.put('/notifications/mark-all-read', {});
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }
}
