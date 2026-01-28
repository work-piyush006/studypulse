import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationStore {
  static const _key = 'notification_inbox';

  /// Save notification
  static Future<void> save({
    required String title,
    required String body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];

    final item = jsonEncode({
      'title': title,
      'body': body,
      'time': DateTime.now().toIso8601String(),
    });

    list.insert(0, item); // newest on top
    await prefs.setStringList(_key, list);
  }

  /// Get all notifications
  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];

    return list
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  /// Clear inbox
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
