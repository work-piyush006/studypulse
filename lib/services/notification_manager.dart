import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationManager {
  NotificationManager._();

  static const _enabledKey = 'notifications_enabled';
  static const _countKey = 'notification_permission_count';

  /* ================= INTERNAL ================= */

  static Future<SharedPreferences> _prefs() async {
    return SharedPreferences.getInstance();
  }

  static Future<bool> _isUserEnabled() async {
    final p = await _prefs();
    return p.getBool(_enabledKey) ?? false;
  }

  static Future<void> _setUserEnabled(bool v) async {
    final p = await _prefs();
    await p.setBool(_enabledKey, v);
  }

  static Future<int> _count() async {
    final p = await _prefs();
    return p.getInt(_countKey) ?? 0;
  }

  static Future<void> _incCount() async {
    final p = await _prefs();
    await p.setInt(_countKey, (await _count()) + 1);
  }

  /* ================= PERMISSION ================= */

  static Future<bool> _hasSystemPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /* ================= REQUEST (MAX 2 TIMES) ================= */

  /// Call ONLY on important user actions (exam set, test notification)
  static Future<bool> requestOnce() async {
    if (await _count() >= 2) return false;

    final status = await Permission.notification.request();
    await _incCount();

    if (status.isGranted) {
      await _setUserEnabled(true);
      return true;
    }

    await _setUserEnabled(false);
    return false;
  }

  /* ================= SETTINGS TOGGLE ================= */

  /// Call ONLY from Settings screen switch
  static Future<bool> setFromSettings(bool enable) async {
    if (!enable) {
      await _setUserEnabled(false);
      return false;
    }

    if (await _hasSystemPermission()) {
      await _setUserEnabled(true);
      return true;
    }

    final granted = await requestOnce();
    await _setUserEnabled(granted);
    return granted;
  }

  /* ================= GLOBAL CHECK ================= */

  /// SAFE check → use everywhere else
  static Future<bool> canNotify() async {
    final systemGranted = await _hasSystemPermission();

    // 🔥 AUTO-RECOVER CASE
    // User enabled from system settings manually
    if (systemGranted && !await _isUserEnabled()) {
      await _setUserEnabled(true);
    }

    return systemGranted && await _isUserEnabled();
  }

  /* ================= OEM / SYSTEM SETTINGS ================= */

  /// Universal & Play-Store safe
  static Future<void> openSystemSettings() async {
    await openAppSettings();
  }
}