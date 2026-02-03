import 'package:permission_handler/permission_handler.dart';
import 'notification.dart';

class NotificationManager {
  NotificationManager._();

  /// Can app really notify user?
  static Future<bool> canNotify() async {
    final notif = await Permission.notification.isGranted;

    // Android 12+ exact alarm
    final alarm = await Permission.scheduleExactAlarm.isGranted;

    return notif && alarm;
  }

  /// Open system notification settings
  static Future<void> openSystemSettings() async {
    await openAppSettings();
  }

  /// Toggle from settings screen
  /// true  → enable reminders
  /// false → disable all notifications
  static Future<void> setFromSettings(bool enabled) async {
    if (!enabled) {
      await NotificationService.cancelAll();
      return;
    }

    // Ask permission again if user enabled
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }
}
