// lib/screens/settings.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/notification.dart';
import '../state/exam_state.dart';
import 'about.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  bool _darkMode = false;
  bool _notifications = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final canNotify = await Permission.notification.isGranted;

    if (!mounted) return;
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _notifications = canNotify;
      _loading = false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);

    if (!mounted) return;
    setState(() => _darkMode = value);

    _snack(
      'Theme will apply on next app launch',
    );
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor:
              error ? Colors.redAccent : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _snackWithSettings() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Notifications are blocked'),
          action: SnackBarAction(
            label: 'ALLOW',
            onPressed: openAppSettings,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Appearance',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: _darkMode,
            onChanged: _toggleTheme,
          ),

          const SizedBox(height: 16),
          const Text(
            'Notifications',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          SwitchListTile(
            title: const Text('Study Notifications'),
            value: _notifications,
            onChanged: (v) async {
              if (v) {
                final status =
                    await Permission.notification.request();
                if (!status.isGranted) {
                  _snackWithSettings();
                  return;
                }
              } else {
                await NotificationService.cancelDaily();
              }

              if (!mounted) return;
              setState(() => _notifications = v);

              _snack(
                v
                    ? 'Notifications enabled'
                    : 'Notifications disabled',
              );
            },
          ),

          ListTile(
            enabled: _notifications,
            title: const Text('Test Notification'),
            subtitle: const Text('Preview only'),
            onTap: !_notifications
                ? null
                : () async {
                    final examDate =
                        ExamState.examDate.value;
                    if (examDate == null) {
                      _snack(
                        'Set exam date first',
                        error: true,
                      );
                      return;
                    }

                    final days =
                        ExamState.daysLeft.value;

                    await NotificationService.instant(
                      title: '📘 Exam Countdown',
                      body:
                          '$days days left\nYou’re on track 🚀',
                      save: false,
                    );

                    _snack('Test notification sent');
                  },
          ),

          const Divider(),

          ListTile(
            title: const Text('Privacy Policy'),
            onTap: () => launchUrl(
              Uri.parse(
                'http://studypulse-privacypolicy.blogspot.com',
              ),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            title: const Text('About StudyPulse'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AboutPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}