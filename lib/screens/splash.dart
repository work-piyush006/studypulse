import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home.dart';
import 'permission.dart';
import 'notification_inbox.dart';
import 'oem_permission.dart';

import '../services/ads.dart';
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
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted || _navigated) return;

    try {
      await ExamState.init();
      InternetService.startMonitoring();
      await AdsService.initialize();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();

    final openInbox = prefs.getBool('open_inbox') ?? false;
    final permissionAsked =
        prefs.getInt('notification_permission_count') ?? 0;
    final oemDone = prefs.getBool('oem_permission_done') ?? false;

    final permissionGranted =
        await Permission.notification.isGranted;

    if (!mounted || _navigated) return;
    _navigated = true;

    if (openInbox) {
      await prefs.remove('open_inbox');
      _go(const NotificationInboxScreen());
      return;
    }

    if (!permissionGranted && permissionAsked < 2) {
      _go(const PermissionScreen());
      return;
    }

    if (permissionGranted && !oemDone) {
      await prefs.setBool('oem_permission_done', true);
      _go(const OemPermissionScreen());
      return;
    }

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
                  color: isDark
                      ? Colors.grey
                      : Colors.black54,
                ),
              ),

              const SizedBox(height: 28),

              // 🔄 LOADER
              const CircularProgressIndicator(strokeWidth: 2),
            ],
          ),
        ),
      ),
    );
  }
}