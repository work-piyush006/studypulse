// lib/screens/splash.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home.dart';
import '../tools/exam.dart';
import '../services/notification.dart';
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

  @override
  void initState() {
    super.initState();

    // 🚀 Run after first frame only
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _start();
    });
  }

  Future<void> _start() async {
    try {
      // 👁️ Small visual delay (UX only)
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted || _navigated) return;

      final prefs = await SharedPreferences.getInstance();

      /* ================= DEEP LINK FROM NOTIFICATION ================= */

      final route = prefs.getString('notification_route');
      if (route != null) {
        await prefs.remove('notification_route');
        _navigateOnce(() {
          if (route == '/notifications') {
            return const NotificationInboxScreen();
          }
          if (route == '/exam') {
            return const ExamCountdownPage();
          }
          return const Home();
        });
        return;
      }

      /* ================= CORE INIT (SAFE) ================= */

      // 🔥 Init notifications HERE (never in main)
      await NotificationService.init();

      /* ================= PERMISSION FLOW ================= */

      final asked =
          prefs.getInt('notification_permission_count') ?? 0;
      final oemDone =
          prefs.getBool('oem_permission_done') ?? false;

      final granted = await Permission.notification.isGranted
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () => false,
          );

      if (!granted && asked < 2) {
        _navigateOnce(() => const PermissionScreen());
        return;
      }

      if (granted && !oemDone) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const OemWarningScreen(),
          ),
        );
      }

      _navigateOnce(() => const Home());
    } catch (e) {
      // 🧯 HARD FAIL-SAFE — app must NEVER stay on splash
      _navigateOnce(() => const Home());
    }
  }

  /* ================= SAFE NAVIGATION ================= */

  void _navigateOnce(Widget Function() builder) {
    if (!mounted || _navigated) return;
    _navigated = true;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => builder()),
    );
  }

  /* ================= UI ================= */

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
              const SizedBox(height: 28),
              const CircularProgressIndicator(strokeWidth: 2),
            ],
          ),
        ),
      ),
    );
  }
}