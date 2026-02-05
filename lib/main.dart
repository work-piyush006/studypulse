import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'app_root.dart';
import 'core/internet_controller.dart';
import 'state/theme_state.dart';

/// 🔥 BACKGROUND FCM HANDLER (TOP LEVEL ONLY)
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // 🛡️ SAFETY: Avoid double init
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase init (HARDENED – 10/10)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeState.mode,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'StudyPulse',
          debugShowCheckedModeBanner: false,

          // 🌞 Light Theme
          theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,
          ),

          // 🌙 Dark Theme
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
          ),

          // 🔥 Dynamic Theme Switch
          themeMode: mode,

          // 🚀 Single entry point
          home: const AppRoot(),
        );
      },
    );
  }
}
