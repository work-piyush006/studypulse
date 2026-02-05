import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../state/theme_state.dart';
import 'about.dart';
import 'auth_gate.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  bool _darkMode = false;
  bool _notificationsAllowed = false;
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
    final allowed = await Permission.notification.isGranted;

    if (!mounted) return;
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _notificationsAllowed = allowed;
      _loading = false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);

    ThemeState.mode.value =
        value ? ThemeMode.dark : ThemeMode.light;

    if (!mounted) return;
    setState(() => _darkMode = value);
  }

  /* ================= LOGOUT ================= */

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'You will be signed out and redirected to login screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'LOGOUT',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 🔥 Firebase sign out
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    // 🔁 Reset navigation → AuthGate
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  /* ================= UI HELPERS ================= */

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _snackWithSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            const Text('Notifications permission is blocked'),
        action: SnackBarAction(
          label: 'ALLOW',
          onPressed: openAppSettings,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
      );

  Widget _card(Widget child) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: child,
      );

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
          _section('Appearance'),
          _card(
            SwitchListTile(
              title: const Text('Dark Mode'),
              secondary: const Icon(Icons.dark_mode_outlined),
              value: _darkMode,
              onChanged: _toggleTheme,
            ),
          ),

          _section('Notifications'),
          _card(
            SwitchListTile(
              title:
                  const Text('Allow Study Notifications'),
              subtitle: const Text(
                'Required to receive exam alerts',
              ),
              secondary: const Icon(
                  Icons.notifications_active_outlined),
              value: _notificationsAllowed,
              onChanged: (v) async {
                if (!v) {
                  _snack(
                    'Disable notifications from system settings',
                  );
                  openAppSettings();
                  return;
                }

                final status =
                    await Permission.notification.request();
                final allowed = status.isGranted;

                setState(
                    () => _notificationsAllowed = allowed);

                if (!allowed) {
                  _snackWithSettings();
                } else {
                  _snack('Notifications enabled');
                }
              },
            ),
          ),

          _section('About'),
          _card(
            ListTile(
              leading:
                  const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              onTap: () => launchUrl(
                Uri.parse(
                  'http://studypulse-privacypolicy.blogspot.com',
                ),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
          _card(
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About StudyPulse'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AboutPage(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // 🔴 LOGOUT BUTTON
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _logout,
            child: const Text(
              'Logout',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}