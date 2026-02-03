import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home.dart';
import '../services/fcm_service.dart';
import 'permission.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  static const _permAskKey = 'notification_permission_ask_count';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // 🔥 INIT FCM FIRST
    FCMService.init();

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted || _navigated) return;

    final prefs = await SharedPreferences.getInstance();
    final asked = prefs.getInt(_permAskKey) ?? 0;

    final status = await Permission.notification.status;

    // ✅ Already granted → Home
    if (status.isGranted) {
      _goHome();
      return;
    }

    // ❌ Permanently denied → Home (never force)
    if (status.isPermanentlyDenied) {
      _goHome();
      return;
    }

    // 🔁 Ask max 2 times
    if (asked < 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const PermissionScreen(),
        ),
      );

      await prefs.setInt(_permAskKey, asked + 1);
    }

    _goHome();
  }

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Home()),
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