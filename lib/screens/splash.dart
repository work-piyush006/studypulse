// lib/screens/splash.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home.dart';
import '../tools/exam.dart';
import 'permission.dart';
import 'notification_inbox.dart';
import 'oem_permission.dart';

import '../services/ads.dart';
import '../services/internet.dart';

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
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted || _navigated) return;

    final prefs = await SharedPreferences.getInstance();

    final route = prefs.getString('notification_route');
    if (route != null) {
      await prefs.remove('notification_route');
      _navigated = true;

      if (route == '/notifications') {
        _replace(const NotificationInboxScreen());
        return;
      }

      if (route == '/exam') {
        _replace(const ExamCountdownPage());
        return;
      }

      _replace(const Home());
      return;
    }

    try {
      InternetService.startMonitoring();
      await AdsService.initialize();
    } catch (_) {}

    final openInbox = prefs.getBool('open_inbox') ?? false;
    final asked =
        prefs.getInt('notification_permission_count') ?? 0;
    final oemDone = prefs.getBool('oem_permission_done') ?? false;
    final granted =
        await Permission.notification.isGranted;

    _navigated = true;

    if (openInbox) {
      await prefs.remove('open_inbox');
      _replace(const NotificationInboxScreen());
      return;
    }

    if (!granted && asked < 2) {
      _replace(const PermissionScreen());
      return;
    }

    if (granted && !oemDone) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => OemWarningScreen(), // ❌ no const
        ),
      );
      _replace(const Home());
      return;
    }

    _replace(const Home());
  }

  void _replace(Widget page) {
    if (!mounted) return;
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
                style:
                    TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
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