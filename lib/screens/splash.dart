import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home.dart';
import '../screens/permission.dart';
import '../screens/notification_inbox.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // ⏳ Splash delay
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();

    // 🔔 Opened by notification tap?
    final openInbox = prefs.getBool('open_inbox') ?? false;

    // 🔐 Permission already asked?
    final permissionAsked =
        prefs.getBool('notification_permission_asked') ?? false;

    // 🔔 CASE 1: Notification tap → OPEN INBOX
    if (openInbox) {
      await prefs.remove('open_inbox'); // reset flag

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const NotificationInboxScreen(),
        ),
      );
      return;
    }

    // 🔐 CASE 2: Permission not asked yet
    if (!permissionAsked) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PermissionScreen(),
        ),
      );
      return;
    }

    // ✅ CASE 3: Normal app open
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const Home(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 120,
              ),
              const SizedBox(height: 20),
              const Text(
                'StudyPulse',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Focus • Track • Succeed',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
