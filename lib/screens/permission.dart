// lib/screens/permission.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool loading = false;

  Future<void> _requestPermission() async {
    if (loading) return;
    setState(() => loading = true);

    // ONLY ask permission — NO counters here
    await Permission.notification.request();

    if (!mounted) return;
    setState(() => loading = false);

    Navigator.pop(context);
  }

  Future<void> _skip() async {
    Navigator.pop(context);
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
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Enable Notifications',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'We use notifications to:\n'
                '• Remind you about exams\n'
                '• Send daily motivation\n'
                '• Keep you on track\n\n'
                'You can change this anytime in settings.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _requestPermission,
                  child: loading
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Text('Allow & Continue'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: loading ? null : _skip,
                  child: const Text('Skip for now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}