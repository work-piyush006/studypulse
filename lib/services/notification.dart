import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification.dart';
import '../home.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _autoCheck();
  }

  /// 🔹 Auto skip if permission already handled
  Future<void> _autoCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final asked = prefs.getBool('notif_permission_asked') ?? false;

    if (asked) {
      _goHome();
    }
  }

  /// 🔔 Ask notification permission ONLY ONCE
  Future<void> _requestPermission() async {
    setState(() => loading = true);

    await NotificationService.requestPermissionOnce();

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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔔 ICON
            Container(
              height: 110,
              width: 110,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active,
                size: 60,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 30),

            // TITLE
            const Text(
              'Enable Notifications',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // DESCRIPTION
            const Text(
              'StudyPulse sends you exam reminders and daily motivation '
              'so you never miss an important day.',
              style: TextStyle(color: Colors.grey, height: 1.5),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : _requestPermission,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Allow Notifications',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 14),

            // SKIP
            TextButton(
              onPressed: loading ? null : _goHome,
              child: const Text(
                'Skip for now',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
