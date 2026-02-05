import 'package:flutter/material.dart';

import 'auth_gate.dart';

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
    _start();
  }

  Future<void> _start() async {
    // ⏳ Splash delay (UI only)
    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted || _navigated) return;

    _navigated = true;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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