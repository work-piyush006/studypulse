// lib/screens/splash.dart
import 'oem_permission.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home.dart';
import 'permission.dart';
import 'notification_inbox.dart';

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
    // ⏱ Minimum splash
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
    final permissionGranted =
        await Permission.notification.isGranted;

    if (!mounted || _navigated) return;
    _navigated = true;

    // 📥 Notification deep link
    if (openInbox) {
      await prefs.remove('open_inbox');
      _go(const NotificationInboxScreen());
      return;
    }

    // 🔔 Permission screen (ONLY navigation)
    if (!permissionGranted && permissionAsked < 2) {
  _go(const PermissionScreen());
  return;
}

// 🔥 OEM SAFETY CHECK (Android 13+)
if (permissionGranted) {
  _go(const OemPermissionScreen());
  return;
}

    // ✅ Home
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
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}