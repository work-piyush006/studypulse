// lib/screens/permission.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home.dart';
import '../services/notification.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool loading = false;
  static const String _countKey = 'notification_permission_count';

  Future<void> _requestPermission() async {
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_countKey) ?? 0;
    await prefs.setInt(_countKey, count + 1);

    final status = await Permission.notification.request();

    if (status.isGranted) {
      // 🔥 Android 13–15 settle window
      await Future.delayed(const Duration(milliseconds: 800));

      // 🔥 Re-init notification system AFTER permission
      await NotificationService.init();
    }

    if (!mounted) return;
    setState(() => loading = false);
    _goHome();
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Home()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              Center(
                child: Icon(
                  Icons.notifications_active_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Enable Notifications',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'We use notifications to:\n'
                '• Remind you about exams\n'
                '• Send daily motivation\n'
                '• Keep you on track\n\n'
                'You can change this anytime in settings.',
                style: TextStyle(fontSize: 15),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _requestPermission,
                  child: loading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        )
                      : const Text(
                          'Allow & Continue',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: loading ? null : _goHome,
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}