// lib/services/notification_manager.dart

import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationManager {
  NotificationManager._();

  static const String _prefsKey = 'notifications_enabled';

  /* ================= USER TOGGLE ================= */

  static Future<bool> _isUserEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  static Future<void> _setUserEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }

  /* ================= PERMISSION ================= */

  static Future<bool> _hasPermission() async {
    return Permission.notification.isGranted;
  }

  static Future<bool> _requestPermission() async {
    final status = await Permission.notification.status;

    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /* ================= PUBLIC API ================= */

  /// ✅ Call ONLY from Settings toggle
  static Future<bool> setNotifications(bool enable) async {
    if (!enable) {
      await _setUserEnabled(false);
      return false;
    }

    final allowed = await _requestPermission();
    if (!allowed) {
      await _setUserEnabled(false);
      return false;
    }

    await _setUserEnabled(true);
    return true;
  }

  /// ✅ Use EVERYWHERE else
  static Future<bool> canNotify() async {
    final enabled = await _isUserEnabled();
    if (!enabled) return false;
    return _hasPermission();
  }

  static Future<void> openSystemSettings() async {
    await openAppSettings();
  }
}