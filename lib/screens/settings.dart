// lib/screens/settings.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart'; // ThemeController
import '../services/notification.dart';

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

    if (!mounted) return;
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _loading = false;
    });
  }

  /* ================= DARK MODE ================= */

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);

    // 🔥 INSTANT APPLY (NO RESTART, NO BLACK SCREEN)
    await ThemeController.of(context).toggleTheme(value);

    if (!mounted) return;
    setState(() => _darkMode = value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Dark Mode Enabled 🌙' : 'Light Mode Enabled ☀️',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /* ================= NOTIFICATIONS ================= */

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);

    if (!value) {
      // 🔕 Cancel all scheduled notifications
      await NotificationService.cancelAll();
    }

    if (!mounted) return;
    setState(() => _notificationsEnabled = value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Notifications Enabled 🔔'
              : 'Notifications Disabled 🔕',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /* ================= UI HELPERS ================= */

  Widget _settingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context)
              .colorScheme
              .primary
              .withOpacity(0.12),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: trailing,
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
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🌙 DARK MODE
          _settingTile(
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            subtitle: 'Reduce eye strain at night',
            trailing: Switch(
              value: _darkMode,
              onChanged: _toggleDarkMode,
            ),
          ),

          // 🔔 NOTIFICATIONS
          _settingTile(
            icon: Icons.notifications_active_rounded,
            title: 'Notifications',
            subtitle: 'Exam reminders & alerts',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'More Features Coming Soon',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            elevation: 0,
            child: Container(
              height: 90,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.05),
              ),
              child: const Text(
                '🚀 Premium tools & smart study features\ncoming soon!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 10),

          const Center(
            child: Text(
              'StudyPulse v1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}