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

  bool _checked = false;
  bool _showPermissionScreen = false;

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
      setState(() => _checked = true);
      return;
    }

    if (asked < 2) {
      setState(() => _showPermissionScreen = true);
      await prefs.setInt(_key, asked + 1);
      return;
    }

    setState(() => _checked = true);
  }

  @override
  Widget build(BuildContext context) {
    // 🔐 Still deciding
    if (!_checked && !_showPermissionScreen) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 🔔 Ask permission screen
    if (_showPermissionScreen) {
      return const PermissionScreen();
    }

    // ✅ Permission flow done → enter app
    return const AppShell();
  }
}
