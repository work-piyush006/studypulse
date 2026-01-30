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
  bool _dark = false;
  bool _notify = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dark = prefs.getBool('dark_mode') ?? false;
      _notify = prefs.getBool('notifications') ?? true;
      _loading = false;
    });
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
            value: _dark,
            onChanged: (v) async {
              final prefs =
                  await SharedPreferences.getInstance();
              await prefs.setBool('dark_mode', v);
              await ThemeController.of(context).toggleTheme(v);
              setState(() => _dark = v);
            },
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            value: _notify,
            onChanged: (v) async {
              await NotificationManager.setUserEnabled(v);
              if (!v) {
                await NotificationService.cancelDaily();
              }
              setState(() => _notify = v);
            },
          ),
          const SizedBox(height: 20),
          ListTile(
            title: const Text('Test Notification'),
            enabled: _notify,
            onTap: !_notify
                ? null
                : () {
                    NotificationService.showInstant(
                      context: context,
                      daysLeft: 10,
                      quote: 'Everything is working 🚀',
                    );
                  },
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            onTap: () {
              launchUrl(
                Uri.parse(
                  'http://studypulse-privacypolicy.blogspot.com',
                ),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
          ListTile(
            title: const Text('About'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AboutPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}