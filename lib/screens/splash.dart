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
  bool _navigated = false;

  static const _permKey = 'notification_permission_count';
  static const _oemKey = 'oem_permission_done';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    try {
      // Small delay for logo visibility
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted || _navigated) return;

      final prefs = await SharedPreferences.getInstance();

      /* ================= DEEP LINK (from notification tap) ================= */
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

      /* ================= NOTIFICATION PERMISSION (Android 13+) ================= */
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

      // Re-check after permission screen
      final canNotify = await Permission.notification.isGranted;

      /* ================= INIT SERVICES (ONLY IF PERMISSION GRANTED) ================= */
      if (canNotify) {
        await NotificationService.init();
        await ExamState.init();
      }

      /* ================= OEM / EXACT ALARM ADVISORY ================= */
      if (canNotify && !(prefs.getBool(_oemKey) ?? false)) {
        final exactGranted =
            await Permission.scheduleExactAlarm.isGranted;

        if (!exactGranted) {
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
    if (_navigated || !mounted) return;
    _navigated = true;
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
              // 🔥 LOGO
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

              // 🔥 APP NAME
              const Text(
                'StudyPulse',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              // 🔥 TAGLINE
              Text(
                'Focus • Track • Succeed',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey : Colors.black54,
                ),
              ),

              const SizedBox(height: 32),

              // 🔄 LOADER
              const CircularProgressIndicator(strokeWidth: 2),
            ],
          ),
        ),
      ),
    );
  }
}