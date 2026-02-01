// lib/main.dart
import 'package:flutter/material.dart';

import 'screens/splash.dart';
import 'services/internet_guard.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudyPulseApp());
}

class StudyPulseApp extends StatelessWidget {
  const StudyPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'StudyPulse',
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      builder: (_, child) =>
          child == null
              ? const SizedBox()
              : InternetGuard(child: child),
      home: const SplashScreen(),
    );
  }
}