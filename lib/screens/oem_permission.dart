import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OemPermissionScreen extends StatefulWidget {
  const OemPermissionScreen({super.key});

  @override
  State<OemPermissionScreen> createState() => _OemPermissionScreenState();
}

class _OemPermissionScreenState extends State<OemPermissionScreen> {
  static const _doneKey = 'oem_permission_done';

  Future<void> _markDoneAndExit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_doneKey, true);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _openRelevantSettings() async {
    // Universal fallback (Play-Store safe)
    await openAppSettings();
  }

  String _oemName() {
    if (!Platform.isAndroid) return 'your phone';
    return 'your phone'; // keep wording generic (Play-safe)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allow Background Notifications'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                size: 64,
              ),
              const SizedBox(height: 24),

              const Text(
                'One Last Important Step',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                '${_oemName()} may block exam reminders in the background '
                'to save battery.\n\n'
                'To make sure you never miss an exam reminder, '
                'please allow background activity for StudyPulse.',
                style: const TextStyle(fontSize: 15),
              ),

              const SizedBox(height: 20),

              const Text(
                'Please check these settings:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              const Text('• Battery optimization → Disabled'),
              const Text('• Background activity → Allowed'),
              const Text('• Auto-start → Allowed (if available)'),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _openRelevantSettings,
                  child: const Text('OPEN SETTINGS'),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: _markDoneAndExit,
                child: const Text('I’ve done this'),
              ),

              TextButton(
                onPressed: _markDoneAndExit,
                child: const Text('I’ll do it later'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}