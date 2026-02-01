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
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted || _navigated) return;

      final prefs = await SharedPreferences.getInstance();

      /* ===== Notification Deep Link ===== */
      final route = prefs.getString('notification_route');
      if (route != null) {
        await prefs.remove('notification_route');
        _go(() {
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

      /* ===== Init notifications (safe) ===== */
      await NotificationService.init();

      /* ===== Permission Logic ===== */
      final asked =
          prefs.getInt('notification_permission_count') ?? 0;
      final granted = await Permission.notification.isGranted;

      // 🔥 FIRST TIME or ONE RETRY
      if (!granted && asked < 2) {
        _go(() => const PermissionScreen());
        return;
      }

      /* ===== OEM Warning (ONLY if granted) ===== */
      final oemDone =
          prefs.getBool('oem_permission_done') ?? false;

      if (granted && !oemDone) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const OemWarningScreen(),
          ),
        );
      }

      _go(() => const Home());
    } catch (_) {
      _go(() => const Home());
    }
  }

  void _go(Widget Function() builder) {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => builder()),
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
                    fontSize: 26, fontWeight: FontWeight.bold),
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