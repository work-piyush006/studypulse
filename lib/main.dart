// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash.dart';
import 'screens/notification_inbox.dart';
import 'tools/exam.dart';
import 'services/notification.dart';
import 'services/internet_guard.dart';
import 'state/exam_state.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudyPulseBootstrap());
}

/* ================= BOOTSTRAP ================= */

class StudyPulseBootstrap extends StatelessWidget {
  const StudyPulseBootstrap({super.key});

  Future<void> _init() async {
    await ExamState.init();
    await NotificationService.init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _init(),
      builder: (_, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return const StudyPulseApp();
      },
    );
  }
}

/* ================= APP ================= */

class StudyPulseApp extends StatefulWidget {
  const StudyPulseApp({super.key});

  @override
  State<StudyPulseApp> createState() => _StudyPulseAppState();
}

class _StudyPulseAppState extends State<StudyPulseApp> {
  ThemeMode _theme = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;
    setState(() {
      _theme = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> toggleTheme(bool dark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', dark);
    setState(() {
      _theme = dark ? ThemeMode.dark : ThemeMode.light;
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
        themeMode: _theme,
        theme: ThemeData(useMaterial3: true),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        routes: {
          '/exam': (_) => const ExamCountdownPage(),
          '/notifications': (_) => const NotificationInboxScreen(),
        },
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

  static ThemeController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeController>()!;

  @override
  bool updateShouldNotify(covariant ThemeController oldWidget) =>
      toggleTheme != oldWidget.toggleTheme;
}