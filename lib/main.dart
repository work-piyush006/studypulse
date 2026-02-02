// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash.dart';
import 'services/internet_guard.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  

  runApp(const StudyPulseApp());
}

/* ================= APP ================= */

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

  Future<void> toggleTheme(bool dark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', dark);

    if (!mounted) return;
    setState(() {
      _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemeController(
      toggleTheme: toggleTheme,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'StudyPulse',
        themeMode: _themeMode,
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
      ),
    );
  }
}

/* ================= THEME CONTROLLER ================= */

class ThemeController extends InheritedWidget {
  final Future<void> Function(bool) toggleTheme;

  const ThemeController({
    super.key,
    required this.toggleTheme,
    required Widget child,
  }) : super(child: child);

  static ThemeController of(BuildContext context) {
    final controller =
        context.dependOnInheritedWidgetOfExactType<ThemeController>();
    assert(controller != null, 'ThemeController not found');
    return controller!;
  }

  @override
  bool updateShouldNotify(covariant ThemeController oldWidget) =>
      toggleTheme != oldWidget.toggleTheme;
}