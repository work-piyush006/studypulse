import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationHealthScreen extends StatefulWidget {
  const NotificationHealthScreen({super.key});

  @override
  State<NotificationHealthScreen> createState() =>
      _NotificationHealthScreenState();
}

class _NotificationHealthScreenState
    extends State<NotificationHealthScreen> {
  bool _notif = false;
  bool _alarm = true; // default true (important)
  bool _battery = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    _notif = await Permission.notification.isGranted;

    // Exact alarm only matters on Android 12+
    if (Platform.isAndroid) {
      final sdk = await _androidSdk();
      if (sdk >= 31) {
        _alarm = await Permission.scheduleExactAlarm.isGranted;
      }
    }

    // Battery optimization (Android only)
    if (Platform.isAndroid) {
      final status =
          await Permission.ignoreBatteryOptimizations.status;
      _battery = status.isGranted;
    }

    if (mounted) setState(() {});
  }

  bool get ready => _notif && _alarm && _battery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _tile(
              'Allow Notifications',
              'Required to remind you about exams',
              _notif,
              Permission.notification,
            ),
            _tile(
              'Allow Exact Alarms',
              'Needed for exam-day alerts',
              _alarm,
              Permission.scheduleExactAlarm,
              androidOnly: true,
            ),
            _tile(
              'Disable Battery Optimization',
              'Prevents reminders from being killed',
              _battery,
              Permission.ignoreBatteryOptimizations,
              androidOnly: true,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: ready ? () => Navigator.pop(context) : null,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    String title,
    String subtitle,
    bool ok,
    Permission permission, {
    bool androidOnly = false,
  }) {
    if (androidOnly && !Platform.isAndroid) {
      return const SizedBox.shrink();
    }

    return ListTile(
      leading: Icon(
        ok ? Icons.check_circle : Icons.warning_amber_rounded,
        color: ok ? Colors.green : Colors.orange,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: ok
          ? null
          : TextButton(
              child: const Text('FIX'),
              onPressed: () async {
                final status = await permission.request();
                if (status.isPermanentlyDenied) {
                  await openAppSettings();
                }
                await _check();
              },
            ),
    );
  }

  Future<int> _androidSdk() async {
    try {
      return int.parse(
        (await Process.run('getprop', ['ro.build.version.sdk']))
            .stdout
            .toString()
            .trim(),
      );
    } catch (_) {
      return 30;
    }
  }
}