// lib/screens/splash.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home.dart';
import '../state/exam_state.dart';
import '../services/notification.dart';
import '../tools/exam.dart';
import 'permission.dart';
import 'notification_inbox.dart';
import 'oem_warning.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _done = false;

  static const _permKey = 'notification_permission_count';
  static const _oemKey = 'oem_permission_done';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    try {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted || _done) return;

      final prefs = await SharedPreferences.getInstance();

      // 🔥 INIT FIRST (critical for Android 13+)
      await NotificationService.init();
      await ExamState.init();

      // 🔔 Notification deep link
      final route = prefs.getString('notification_route');
      if (route != null) {
        await prefs.remove('notification_route');
        _go(
          route == '/exam'
              ? const ExamCountdownPage()
              : route == '/notifications'
                  ? const NotificationInboxScreen()
                  : const Home(),
        );
        return;
      }

      // 🔐 Notification permission (max 2 attempts)
      final asked = prefs.getInt(_permKey) ?? 0;
      final granted = await Permission.notification.isGranted;

      if (!granted && asked < 2) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const PermissionScreen(),
          ),
        );
        await prefs.setInt(_permKey, asked + 1);
      }

      // 🔋 OEM / Exact alarm advisory (not blocking)
      if (await Permission.notification.isGranted &&
          !(prefs.getBool(_oemKey) ?? false)) {
        if (!(await Permission.scheduleExactAlarm.isGranted)) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => const OemWarningScreen(),
            ),
          );
        }
        await prefs.setBool(_oemKey, true);
      }

      _go(const Home());
    } catch (_) {
      _go(const Home());
    }
  }

  void _go(Widget page) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 110,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.school_rounded,
                  size: 90,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'StudyPulse',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Focus • Track • Succeed',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey : Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(strokeWidth: 2),
            ],
          ),
        ),
      ),
    );
  }
}