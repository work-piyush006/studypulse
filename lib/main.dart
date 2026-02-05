import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'app_root.dart';
import 'core/internet_controller.dart';

/// 🔥 BACKGROUND HANDLER (TOP LEVEL ONLY)
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase init (SAFE)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // 🔔 Register FCM background handler
  FirebaseMessaging.onBackgroundMessage(
    _firebaseBackgroundHandler,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => InternetController()..start(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const AppRoot(),
    );
  }
}