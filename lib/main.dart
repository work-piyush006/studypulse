// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/internet.dart';
import 'screens/splash.dart';
import 'state/theme_state.dart';
import 'screens/no_internet.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? false;
  ThemeState.mode.value =
      isDark ? ThemeMode.dark : ThemeMode.light;

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

          // 🔥 GLOBAL INTERNET GUARD
          builder: (context, child) {
            return ValueListenableBuilder<bool>(
              valueListenable: InternetService.isConnected,
              builder: (_, connected, __) {
                if (!connected) {
                  return const NoInternetScreen();
                }
                return child!;
              },
            );
          },

          home: const SplashScreen(),
        );
      },
    );
  }
}