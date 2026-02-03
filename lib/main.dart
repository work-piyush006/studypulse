// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/internet.dart';
import 'screens/splash.dart';
import 'state/theme_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌙 Load saved theme
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? false;
  ThemeState.mode.value =
      isDark ? ThemeMode.dark : ThemeMode.light;

  // 🌐 Start internet monitoring (logic handled in screens)
  InternetService.startMonitoring();

  runApp(const StudyPulseApp());
}

class StudyPulseApp extends StatelessWidget {
  const StudyPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeState.mode,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'StudyPulse',
          themeMode: mode,
          theme: ThemeData(useMaterial3: true),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
          ),

          // ❌ NO global internet guard here
          // ❌ NO permission logic here
          // ✅ Splash handles everything
          home: const SplashScreen(),
        );
      },
    );
  }
}