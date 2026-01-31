import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationManager {
  NotificationManager._();

  static const String _prefsKey = 'notifications_enabled';

  /* ================= USER TOGGLE ================= */

  static Future<bool> _isUserEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false; // default OFF
  }

  static Future<void> _setUserEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }

  /* ================= SYSTEM PERMISSION ================= */

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

  /* ================= SETTINGS TOGGLE (ONLY PLACE TO ASK) ================= */

  /// ✅ Call ONLY from Settings switch
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

  /* ================= GLOBAL CHECK (NO DIALOG HERE) ================= */

  /// ✅ Use everywhere else (exam, test, schedule)
  static Future<bool> canNotify() async {
    final enabled = await _isUserEnabled();
    if (!enabled) return false;

    return await _hasPermission(); // ❌ never ask here
  }

  /* ================= HELPERS ================= */

  static Future<void> openSystemSettings() async {
    await openAppSettings();
  }
}