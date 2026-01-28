import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash.dart';
import 'services/notification.dart'; // 🔥 ADD
import 'services/internet.dart';     // 🔥 ADD (next step)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔔 init notification service ONLY ONCE
  await NotificationService.init();

  // 🌐 start internet monitoring (global)
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

  /// 🔥 NO CHANGE – already correct
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

        home: const SplashScreen(),
      ),
    );
  }
}

///
/// Global Theme Controller (UNCHANGED – already clean)
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
