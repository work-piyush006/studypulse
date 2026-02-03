import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'screens/splash.dart';
import 'services/internet.dart';
import 'services/fcm_service.dart';

/// 🔥 BACKGROUND HANDLER (TOP LEVEL ONLY)
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌐 Internet monitor
  InternetService.startMonitoring();

  // 🔥 Firebase init
  await Firebase.initializeApp();
await FCMService.init(); // 🔥 REQUIRED

  // 🔔 FCM background handler
  FirebaseMessaging.onBackgroundMessage(
    _firebaseBackgroundHandler,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}