import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initFcm() async {
    await _firebaseMessaging.requestPermission();
    _fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $_fcmToken');

    if (_fcmToken != null) {
      await _sendTokenToServer(_fcmToken!);
    }

    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _sendTokenToServer(newToken);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message opened: ${message.notification?.title}');
      _handleNotificationTap(message);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.title}');
    });
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      await _apiService.updateFcmToken(token);
      print('FCM token sent to server successfully');
    } catch (e) {
      print('Error sending FCM token to server: $e');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    if (message.data['type'] == 'CHANNEL_CREATED') {
      String? channelId = message.data['channelId'];
      if (channelId != null) {
        print('Navigate to channel: $channelId');
      }
    }
  }
}
