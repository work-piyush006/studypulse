// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash.dart';
import 'services/internet.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌐 Start internet monitoring ONCE (no UI logic here)
  InternetService.startMonitoring();

  runApp(const StudyPulseApp());
}

class StudyPulseApp extends StatefulWidget {
  const StudyPulseApp({super.key});

  @override
  State<StudyPulseApp> createState() => _StudyPulseAppState();
}

class _StudyPulseAppState extends State<StudyPulseApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;

    if (!mounted) return;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'StudyPulse',

      themeMode: _themeMode,
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
      ),

      // ❌ NO permission logic
      // ❌ NO internet guard
      // ❌ NO async work
      // ✅ Splash handles everything
      home: const SplashScreen(),
    );
  }
}