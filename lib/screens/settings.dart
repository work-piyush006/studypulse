// lib/screens/settings.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../services/notification.dart';
import '../services/notification_manager.dart';
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
      _load(); // resync after system settings
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final canNotify = await NotificationManager.canNotify();

    if (!mounted) return;
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _notifications = canNotify;
      _loading = false;
    });
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor:
              error ? Colors.redAccent : Colors.green,
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
            onPressed: NotificationManager.openSystemSettings,
          ),
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
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: _darkMode,
            onChanged: (v) async {
              final prefs =
                  await SharedPreferences.getInstance();
              await prefs.setBool('dark_mode', v);
              await ThemeController.of(context)
                  .toggleTheme(v);
              setState(() => _darkMode = v);
            },
          ),
          SwitchListTile(
            title: const Text('Study Notifications'),
            value: _notifications,
            onChanged: (v) async {
              final ok =
                  await NotificationManager.setNotifications(v);

              setState(() => _notifications = ok);

              if (!ok && v) {
                _snackWithSettings();
              } else {
                _snack(ok
                    ? 'Notifications enabled'
                    : 'Notifications disabled');
              }
            },
          ),
          ListTile(
            enabled: _notifications,
            title: const Text('Test Notification'),
            onTap: !_notifications
                ? null
                : () async {
                    final examDate =
                        ExamState.examDate.value;
                    if (examDate == null) {
                      _snack(
                        'Please set exam date first',
                        error: true,
                      );
                      return;
                    }

                    final r =
                        await NotificationService.showInstant(
                      daysLeft:
                          ExamState.daysLeft.value,
                      quote: 'You’re on track 🚀',
                      saveToInbox: false,
                    );

                    _snack(
                      r == NotificationResult.success
                          ? 'Test notification sent'
                          : 'Notification blocked',
                      error: r != NotificationResult.success,
                    );
                  },
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            onTap: () => launchUrl(
              Uri.parse(
                  'http://studypulse-privacypolicy.blogspot.com'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            title: const Text('About'),
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