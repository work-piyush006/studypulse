import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/notification.dart';
import '../state/exam_state.dart';
import 'about.dart';
import '../state/theme_state.dart';



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

  // 🔥 INSTANT THEME UPDATE (THIS IS THE KEY LINE)
  ThemeState.mode.value =
      value ? ThemeMode.dark : ThemeMode.light;

  if (!mounted) return;
  setState(() => _darkMode = value);
}
  

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            error ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _snackWithSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
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
              title: const Text('Study Notifications'),
              secondary:
                  const Icon(Icons.notifications_active_outlined),
              value: _notifications,
              onChanged: (v) async {
                bool allowed = false;

                if (v) {
                  final status =
                      await Permission.notification.request();
                  allowed = status.isGranted;
                }

                setState(() => _notifications = allowed);

                if (v && !allowed) {
                  _snackWithSettings();
                } else {
                  _snack(allowed
                      ? 'Notifications enabled'
                      : 'Notifications disabled');
                }
              },
            ),
          ),

          _card(
            ListTile(
              enabled: _notifications,
              leading: const Icon(Icons.notification_add),
              title: const Text('Test Notification'),
              subtitle:
                  const Text('Preview only (not saved)'),
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

                      final days =
                          ExamState.daysLeft.value;

                      await NotificationService.instant(
                        title: '📘 Exam Countdown',
                        body:
                            '$days days left\nYou’re on track 🚀',
                        save: false,
                      );

                      final allowed =
                          await Permission.notification.isGranted;

                      if (!allowed) {
                        _snackWithSettings();
                      } else {
                        _snack('Test notification sent');
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
        ],
      ),
    );
  }
}