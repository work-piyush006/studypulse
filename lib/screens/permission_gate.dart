import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/app_shell.dart';
import 'permission.dart';

class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  static const _key = 'notification_permission_ask_count';

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final asked = prefs.getInt(_key) ?? 0;

    final status = await Permission.notification.status;

    if (status.isGranted || status.isPermanentlyDenied) {
      _goApp();
      return;
    }

    if (asked < 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const PermissionScreen(),
        ),
      );
      await prefs.setInt(_key, asked + 1);
    }

    _goApp();
  }

  void _goApp() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
