import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SystemServiceType {
  authentication,
  notification,
}

class SystemStatus {
  final bool broken;
  final String title;
  final String message;
  final IconData icon;

  const SystemStatus({
    required this.broken,
    required this.title,
    required this.message,
    required this.icon,
  });
}

class SystemStatusService {
  static const _authKey = 'system_auth_broken';
  static const _notifKey = 'system_notif_broken';

  /* ================= SETTERS ================= */

  static Future<void> markAuthBroken(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authKey, value);
  }

  static Future<void> markNotificationBroken(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifKey, value);
  }

  /* ================= GETTERS ================= */

  static Future<SystemStatus> authStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final broken = prefs.getBool(_authKey) ?? false;

    if (!broken) {
      return const SystemStatus(
        broken: false,
        title: '',
        message: '',
        icon: Icons.check_circle_outline,
      );
    }

    return const SystemStatus(
      broken: true,
      title: 'Authentication service broken ⛓️‍💥',
      message:
          "We're working hard to improve the system ❤️‍🩹\nPlease try again later.",
      icon: Icons.lock_outline,
    );
  }

  static Future<SystemStatus> notificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final broken = prefs.getBool(_notifKey) ?? false;

    if (!broken) {
      return const SystemStatus(
        broken: false,
        title: '',
        message: '',
        icon: Icons.notifications_active_outlined,
      );
    }

    return const SystemStatus(
      broken: true,
      title: 'Notification service broken ⛓️‍💥',
      message:
          "Notifications are temporarily paused ❤️‍🩹\nWe're fixing this right now.",
      icon: Icons.notifications_off_outlined,
    );
  }

  /* ================= RESET ================= */

  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
    await prefs.remove(_notifKey);
  }
}
