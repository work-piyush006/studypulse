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
      _load(); // 🔥 resync after system settings
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

  void _snackWithSettings() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              const Text('Notifications are blocked'),
          action: SnackBarAction(
            label: 'ALLOW',
            onPressed:
                NotificationManager.openSystemSettings,
          ),
          behavior: SnackBarBehavior.floating,
        ),
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

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      );

  Widget _card(Widget child) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade200),
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
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Appearance'),
          _card(
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark Mode'),
              value: _darkMode,
              onChanged: (v) async {
                final prefs =
                    await SharedPreferences.getInstance();
                await prefs.setBool('dark_mode', v);
                await ThemeController.of(context)
                    .toggleTheme(v);
                if (!mounted) return;
                setState(() => _darkMode = v);
              },
            ),
          ),

          _section('Notifications'),
          _card(
            SwitchListTile(
              secondary:
                  const Icon(Icons.notifications_active_outlined),
              title: const Text('Study Notifications'),
              value: _notifications,
              onChanged: (v) async {
                final ok =
                    await NotificationManager.setNotifications(v);

                if (!mounted) return;
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

                      final today = DateTime.now();
                      final daysLeft = examDate
                          .difference(DateTime(
                              today.year,
                              today.month,
                              today.day))
                          .inDays;

                      if (daysLeft < 0) {
                        _snack(
                          'Exam date already passed',
                          error: true,
                        );
                        return;
                      }

                      final r =
                          await NotificationService.showInstant(
                        daysLeft: daysLeft,
                        quote: 'You’re on track 🚀',
                        saveToInbox: false,
                      );

                      _snack(
                        r == NotificationResult.success
                            ? 'Test notification sent'
                            : 'Notification blocked',
                        error:
                            r != NotificationResult.success,
                      );
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