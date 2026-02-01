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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.init();
  await ExamState.init();

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? false;

  runApp(
    StudyPulseApp(
      initialTheme: isDark ? ThemeMode.dark : ThemeMode.light,
    ),
  );
}

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
  late ThemeMode _theme;

  @override
  void initState() {
    super.initState();
    _theme = widget.initialTheme;
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
        builder: (c, child) =>
            child == null ? const SizedBox() : InternetGuard(child: child),
        home: const SplashScreen(),
      ),
    );
  }
}

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