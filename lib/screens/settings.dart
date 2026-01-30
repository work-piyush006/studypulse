// lib/screens/settings.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart'; // ThemeController
import '../services/notification.dart';
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

    await ThemeController.of(context).toggleTheme(value);

    if (!mounted) return;
    setState(() => _darkMode = value);

    _snack(
      value ? 'Dark Mode Enabled 🌙' : 'Light Mode Enabled ☀️',
    );
  }

  /* ================= NOTIFICATIONS ================= */

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);

    if (!value) {
      await NotificationService.cancelAllExamNotifications();
    }

    if (!mounted) return;
    setState(() => _notificationsEnabled = value);

    _snack(
      value
          ? 'Notifications Enabled 🔔'
          : 'Notifications Disabled 🔕',
    );
  }

  /* ================= UI HELPERS ================= */

  Widget _settingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.12),
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
        onTap: onTap,
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    const url =
        'http://studypulse-privacypolicy.blogspot.com/2026/01/studypulse-privacy-policy.html';
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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

          // 🧪 TEST NOTIFICATION
          _settingTile(
            icon: Icons.notification_important_rounded,
            title: 'Test Notification',
            subtitle: 'Check if notifications are working',
            onTap: () async {
              await NotificationService.showInstant(
                context: context,
                daysLeft: 10,
                quote: 'Stay consistent. Success will follow.',
              );
            },
          ),

          // 📜 PRIVACY POLICY
          _settingTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data',
            onTap: _openPrivacyPolicy,
          ),

          // ℹ️ ABOUT
          _settingTile(
            icon: Icons.info_outline,
            title: 'About StudyPulse',
            subtitle: 'App details & developer info',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AboutPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 30),
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