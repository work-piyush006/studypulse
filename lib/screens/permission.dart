import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _checkPermissionStatus();
  }

  /// ✅ Decide whether to show this screen or skip it
  Future<void> _checkPermissionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked =
        prefs.getBool('notif_permission_asked') ?? false;

    final status = await Permission.notification.status;

    // ✅ Already granted → skip screen
    if (status.isGranted) {
      _goHome();
      return;
    }

    // ❌ Denied before → don't auto request again
    if (alreadyAsked) {
      // Just stay on screen, user must tap button
      return;
    }
  }

  Future<void> _requestPermission() async {
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_permission_asked', true);

    final status = await Permission.notification.request();

    setState(() => loading = false);

    // ✔ Allow or deny → continue app
    _goHome();
  }

  void _goHome() {
    if (!mounted) return;
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
                '• Show daily motivation\n'
                '• Keep you focused on goals\n\n'
                'You can change this anytime in settings.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
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
