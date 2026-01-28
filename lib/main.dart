import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash.dart';
import 'services/notification.dart';
import 'services/internet.dart';
import 'services/internet_guard.dart';
import 'services/ads.dart'; // 🔥 ADS SERVICE

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 ADS INIT (MANDATORY – bina iske ads kabhi load nahi honge)
  await AdsService.initialize();

  // 🔔 Notification service (only once)
  await NotificationService.init();

  // 🌐 Internet monitoring (global – app fully online)
  InternetService.startMonitoring();

  runApp(const StudyPulseApp());
}

class StudyPulseApp extends StatefulWidget {
  const StudyPulseApp({super.key});

  @override
  State<StudyPulseApp> createState() => _StudyPulseAppState();
}

class _StudyPulseAppState extends State<StudyPulseApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;

    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  /// 🔥 Instant theme apply (no restart needed)
  void toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);

    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemeController(
      toggleTheme: toggleTheme,
      child: MaterialApp(
        title: 'StudyPulse',
        debugShowCheckedModeBanner: false,
        themeMode: _themeMode,

        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorSchemeSeed: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        ),

        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: Colors.blue,
        ),

        // 🌐 INTERNET GUARD (no internet → full screen block)
        home: InternetGuard(
          child: const SplashScreen(),
        ),
      ),
    );
  }
}

///
/// 🌙 Global Theme Controller
/// Allows instant dark/light toggle without restart
///
class ThemeController extends InheritedWidget {
  final void Function(bool) toggleTheme;

  const ThemeController({
    super.key,
    required this.toggleTheme,
    required super.child,
  });

  static ThemeController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeController>()!;
  }

  @override
  bool updateShouldNotify(covariant ThemeController oldWidget) =>
      toggleTheme != oldWidget.toggleTheme;
}
