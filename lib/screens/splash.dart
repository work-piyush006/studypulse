// lib/screens/splash.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
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
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    // ⏱ Minimum splash duration
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted || _navigated) return;

    // 🔹 Core init (never block navigation)
    try {
      InternetService.startMonitoring();
      await AdsService.initialize();
    } catch (_) {}

    // 🔹 Notification init (OEM risky → isolated)
    try {
      await NotificationService.init();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();

    final openInbox = prefs.getBool('open_inbox') ?? false;
    final permissionCount =
        prefs.getInt('notification_permission_count') ?? 0;

    final permissionGranted =
        await Permission.notification.isGranted;

    if (!mounted || _navigated) return;
    _navigated = true;

    // 📥 Deep link from notification
    if (openInbox) {
      await prefs.remove('open_inbox');
      _go(const NotificationInboxScreen());
      return;
    }

    // 🔔 Permission screen logic (MNC-grade)
    // Conditions:
    // - Permission NOT granted
    // - Asked less than 2 times
    if (!permissionGranted && permissionCount < 2) {
      _go(const PermissionScreen());
      return;
    }

    // ✅ Default → Home
    _go(const Home());
  }

  void _go(Widget page) {
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔥 Logo with safe fallback
            Image.asset(
              'assets/logo.png',
              height: 110,
              errorBuilder: (_, __, ___) {
                return Icon(
                  Icons.school_rounded,
                  size: 90,
                  color: Theme.of(context).colorScheme.primary,
                );
              },
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
          ],
        ),
      ),
    );
  }
}