import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();
  String? _fcmToken;
  Function()? onNotificationReceived;
  Function(Map<String, dynamic>)? onIncomingCallReceived;

  String? get fcmToken => _fcmToken;

  Future<void> initFcm() async {
    await _requestPermissions();
    await _initializeLocalNotifications();

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
      if (onNotificationReceived != null) {
        onNotificationReceived!();
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.title}');
      final type = message.data['type'];

      if (type == 'INCOMING_CALL') {
        print('Incoming call notification received in foreground');
        _handleIncomingCall(message);
      } else {
        _showLocalNotification(message);
        if (onNotificationReceived != null) {
          onNotificationReceived!();
        }
      }
    });
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Notification permission status: ${settings.authorizationStatus}');
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
        if (onNotificationReceived != null) {
          onNotificationReceived!();
        }
      },
    );

    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notifications importantes',
      description: 'Canal pour les notifications importantes',
      importance: Importance.high,
      playSound: true,
      showBadge: true,
    );

    const incomingCallChannel = AndroidNotificationChannel(
      'incoming_call_channel',
      'Appels entrants',
      description: 'Canal pour les appels entrants',
      importance: Importance.max,
      playSound: true,
      showBadge: true,
      enableVibration: true,
      enableLights: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(androidChannel);
    await androidPlugin?.createNotificationChannel(incomingCallChannel);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Notifications importantes',
            channelDescription: 'Canal pour les notifications importantes',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
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
    final notificationType = message.data['type'];

    if (notificationType == 'INCOMING_CALL') {
      _handleIncomingCall(message);
    } else if (notificationType == 'CHANNEL_CREATED') {
      String? channelId = message.data['channelId'];
      if (channelId != null) {
        print('Navigate to channel: $channelId');
      }
    } else if (notificationType == 'CLAIM_NEW' ||
        notificationType == 'CLAIM_AFFECTED' ||
        notificationType == 'CLAIM_STATUS_UPDATE') {
      String? claimId = message.data['relatedId'];
      if (claimId != null) {
        print('Navigate to claim: $claimId');
      }
    }
  }

  void _handleIncomingCall(RemoteMessage message) {
    print('=== HANDLING INCOMING CALL FROM FCM ===');
    print('Call data: ${message.data}');

    try {
      final callData = {
        'id': int.parse(message.data['callId'] ?? '0'),
        'callerId': message.data['callerId'] ?? '',
        'callerName': message.data['callerName'] ?? 'Inconnu',
        'callerAvatar': message.data['callerAvatar'] ?? '',
        'channelId': int.parse(message.data['channelId'] ?? '0'),
        'status': 'INITIATED',
      };

      print('Parsed call data: $callData');

      if (callData['id'] == 0 || callData['channelId'] == 0) {
        print('ERROR: Invalid call data (missing callId or channelId)');
        return;
      }

      if (onIncomingCallReceived != null) {
        print('Calling onIncomingCallReceived callback');
        onIncomingCallReceived!(callData);
      } else {
        print('WARNING: onIncomingCallReceived callback is not set!');
      }
    } catch (e, stackTrace) {
      print('Error handling incoming call: $e');
      print('Stack trace: $stackTrace');
    }
  }
}
