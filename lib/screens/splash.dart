// lib/screens/splash.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home.dart';
import 'permission.dart';
import 'notification_inbox.dart';

import '../services/ads.dart';
import '../services/notification.dart';
import '../services/internet.dart';
import '../state/exam_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // 🔹 CORE APP STATE (MUST NEVER FAIL TOGETHER)
    try {
      await ExamState.init();
      InternetService.startMonitoring();
      await AdsService.initialize();
    } catch (_) {
      // swallow → app must continue
    }

    // 🔹 NOTIFICATIONS (OEM-RISKY → ISOLATED)
    try {
      await NotificationService.init();
    } catch (_) {
      // MIUI / Oppo safe
    }

    final prefs = await SharedPreferences.getInstance();

    final openInbox = prefs.getBool('open_inbox') ?? false;
    final permissionAsked =
        prefs.getBool('notification_permission_asked') ?? false;

    if (!mounted) return;

    if (openInbox) {
      await prefs.remove('open_inbox');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const NotificationInboxScreen(),
        ),
      );
      return;
    }

    if (!permissionAsked) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PermissionScreen(),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const Home(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 120),
            Text(
              'StudyPulse',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Focus • Track • Succeed',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}