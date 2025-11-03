import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mgi/firebase_options.dart';
import 'package:mgi/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/channel_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/vote_provider.dart';
import 'providers/document_provider.dart';
import 'providers/claim_provider.dart';
import 'providers/call_provider.dart';
import 'services/api_service.dart';
import 'services/websocket_service.dart';
import 'services/storage_service.dart';
import 'services/building_context_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/auth/building_selection_screen.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
await NotificationService().initFcm();
 FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
  // Initialize services
  await StorageService.init();
  await BuildingContextService().loadBuildingContext();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MGIApp());
}

class MGIApp extends StatelessWidget {
  const MGIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ChannelProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => VoteProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => ClaimProvider()),
        ChangeNotifierProvider(create: (_) => CallProvider()),
      ],
      child: MaterialApp(
        title: 'MGI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/main': (context) => const MainScreen(),
          '/building-selection': (context) => const BuildingSelectionScreen(),
        },
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: child!,
          );
        },
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background message: ${message.notification?.title}');

  final type = message.data['type'];
  if (type == 'INCOMING_CALL') {
    print('Incoming call received in background: ${message.data}');
  }
}