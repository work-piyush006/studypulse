// lib/main.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash.dart';
import 'services/internet_guard.dart';
import 'services/notification.dart';
import 'state/exam_state.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔔 MUST INIT — notifications (ROOT FIX)
  await NotificationService.init();

  // 📅 MUST INIT — exam state (daysLeft / midnight refresh)
  await ExamState.init();

  // 🎨 Load theme before app start
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? false;

  runApp(
    StudyPulseApp(
      initialTheme:
          isDark ? ThemeMode.dark : ThemeMode.light,
    ),
  );
}

/* ================= APP ROOT ================= */

class StudyPulseApp extends StatefulWidget {
  final ThemeMode initialTheme;

  const StudyPulseApp({
    super.key,
    required this.initialTheme,
  });

  @override
  State<StudyPulseApp> createState() => _StudyPulseAppState();
}

class _StudyPulseAppState extends State<StudyPulseApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialTheme;
  }

  Future<void> toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);

    if (!mounted) return;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
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

        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorSchemeSeed: Colors.blue,
        ),

        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: Colors.blue,
        ),

        // 🌐 INTERNET GUARD — SAFE WRAP
        builder: (context, child) {
          if (child == null) return const SizedBox();
          return InternetGuard(child: child);
        },

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
    return context
        .dependOnInheritedWidgetOfExactType<ThemeController>()!;
  }

  @override
  bool updateShouldNotify(covariant ThemeController oldWidget) {
    return toggleTheme != oldWidget.toggleTheme;
  }
}