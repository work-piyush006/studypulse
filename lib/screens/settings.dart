// lib/screens/settings.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../services/notification.dart';
import '../services/notification_manager.dart';
import 'about.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /* ================= LOAD ================= */

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final notify = await NotificationManager.isUserEnabled();

    if (!mounted) return;
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _notificationsEnabled = notify;
      _loading = false;
    });
  }

  /* ================= SNACK ================= */

  void _showSnack(String msg, {bool error = false}) {
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

  /* ================= BUILD ================= */

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
          /* ---------- DARK MODE ---------- */

          SwitchListTile(
            title: const Text('Dark Mode'),
            value: _darkMode,
            onChanged: (value) async {
              final prefs =
                  await SharedPreferences.getInstance();
              await prefs.setBool('dark_mode', value);
              await ThemeController.of(context)
                  .toggleTheme(value);

              if (!mounted) return;
              setState(() => _darkMode = value);
            },
          ),

          /* ---------- NOTIFICATIONS ---------- */

          SwitchListTile(
            title: const Text('Notifications'),
            value: _notificationsEnabled,
            onChanged: (value) async {
              await NotificationManager
                  .setUserEnabled(value);

              if (!value) {
                await NotificationService.cancelDaily();
                _showSnack('Notifications turned OFF');
              } else {
                _showSnack('Notifications turned ON');
              }

              if (!mounted) return;
              setState(() =>
                  _notificationsEnabled = value);
            },
          ),

          const SizedBox(height: 20),

          /* ---------- TEST NOTIFICATION ---------- */

          ListTile(
            title: const Text('Test Notification'),
            enabled: _notificationsEnabled,
            onTap: !_notificationsEnabled
                ? null
                : () async {
                    final result =
                        await NotificationService
                            .showInstant(
                      daysLeft: 10,
                      quote:
                          'Everything is working 🚀',
                    );

                    switch (result) {
                      case NotificationResult.success:
                        _showSnack(
                            'Test notification sent');
                        break;

                      case NotificationResult
                            .permissionDenied:
                        _showSnack(
                          'Enable notification permission in system settings',
                          error: true,
                        );
                        break;

                      case NotificationResult
                            .disabledByUser:
                        _showSnack(
                          'Notifications are turned OFF',
                          error: true,
                        );
                        break;

                      case NotificationResult
                            .invalidDate:
                        _showSnack(
                          'Invalid exam date',
                          error: true,
                        );
                        break;

                      case NotificationResult.failed:
                      default:
                        _showSnack(
                          'Notification failed',
                          error: true,
                        );
                    }
                  },
          ),

          const SizedBox(height: 10),

          /* ---------- PRIVACY POLICY ---------- */

          ListTile(
            title: const Text('Privacy Policy'),
            onTap: () {
              launchUrl(
                Uri.parse(
                  'http://studypulse-privacypolicy.blogspot.com',
                ),
                mode:
                    LaunchMode.externalApplication,
              );
            },
          ),

          /* ---------- ABOUT ---------- */

          ListTile(
            title: const Text('About'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AboutPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}