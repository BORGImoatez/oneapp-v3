import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService{
final FirebaseMessaging _firebaseMessaging=FirebaseMessaging.instance;
initFcm()async{
  await _firebaseMessaging.requestPermission();
  final fcmToken= await _firebaseMessaging.getToken();
  print('fcm token $fcmToken');
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message){
    print('Message: $message.notification?.title');
  });
  FirebaseMessaging.onMessage.listen((RemoteMessage message){
    print('Message: $message.notification?.title');
  });

}
}
