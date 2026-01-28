import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool darkMode = false;
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool('dark_mode') ?? false;
      notificationsEnabled = prefs.getBool('notifications') ?? true;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() => darkMode = value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Dark Mode Enabled' : 'Light Mode Enabled',
        ),
      ),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
    setState(() => notificationsEnabled = value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Notifications Enabled'
              : 'Notifications Disabled',
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    String? subtitle,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Icon(icon, color: Colors.blue),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🌙 Dark Mode
          _settingTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'Reduce eye strain at night',
            trailing: Switch(
              value: darkMode,
              onChanged: _toggleDarkMode,
            ),
          ),

          // 🔔 Notifications
          _settingTile(
            icon: Icons.notifications_active,
            title: 'Notifications',
            subtitle: 'Daily exam reminders & alerts',
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: _toggleNotifications,
            ),
          ),

          const SizedBox(height: 20),

          // 🚀 Future Section
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
                color: Colors.blue.withOpacity(0.05),
              ),
              child: const Text(
                '🚀 Premium tools & smart study features\ncoming soon!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 🧾 App Info
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
