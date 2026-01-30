// lib/services/notification_manager.dart

import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationManager {
  NotificationManager._();

  static const String _prefsKey = 'notifications';

  /// User toggle from Settings
  static Future<bool> isUserEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? true;
  }

  static Future<void> setUserEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }

  /// System permission check
  static Future<bool> hasPermission() async {
    return Permission.notification.isGranted;
  }

  /// Request permission safely (no loop)
  static Future<bool> requestPermissionIfNeeded() async {
    final status = await Permission.notification.status;

    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// ✅ FINAL DECISION (FIXED)
  static Future<bool> canNotify() async {
    final enabled = await isUserEnabled();
    final permission = await hasPermission();
    return enabled && permission;
  }
}