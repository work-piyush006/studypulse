import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationManager {
  NotificationManager._();

  static const _enabledKey = 'notifications_enabled';
  static const _countKey = 'notification_permission_count';

  static Future<bool> _isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<void> _setEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, v);
  }

  static Future<int> _count() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_countKey) ?? 0;
  }

  static Future<void> _incCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey, (await _count()) + 1);
  }

  /// Splash / Permission screen (max 2 times)
  static Future<bool> requestOnce() async {
    if (await _count() >= 2) return false;

    final status = await Permission.notification.request();
    await _incCount();

    if (status.isGranted) {
      await _setEnabled(true);
      return true;
    }

    await _setEnabled(false);
    return false;
  }

  /// ONLY Settings toggle
  static Future<bool> setFromSettings(bool enable) async {
    if (!enable) {
      await _setEnabled(false);
      return false;
    }

    final status = await Permission.notification.status;
    if (status.isGranted) {
      await _setEnabled(true);
      return true;
    }

    return await requestOnce();
  }

  /// Everywhere else (NO dialog)
  static Future<bool> canNotify() async {
    if (!await _isEnabled()) return false;
    return Permission.notification.isGranted;
  }

  static Future<void> openSystemSettings() async {
    await openAppSettings();
  }
}