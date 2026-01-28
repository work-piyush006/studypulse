import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationStore {
  static const String _key = 'notifications';

  /// ✅ Save notification (UNREAD by default)
  static Future<void> save({
    required String title,
    required String body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    List list = raw == null ? [] : jsonDecode(raw);

    list.insert(0, {
      'title': title,
      'body': body,
      'time': DateTime.now().toIso8601String(),
      'read': false,
    });

    await prefs.setString(_key, jsonEncode(list));
  }

  /// 📥 Get all notifications
  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];

    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  /// 🔴 Count unread notifications (for 🔔 badge)
  static Future<int> unreadCount() async {
    final all = await getAll();
    return all.where((n) => n['read'] == false).length;
  }

  /// 👁 Mark ALL as read (when inbox opened)
  static Future<void> markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;

    final List list = jsonDecode(raw);
    for (final n in list) {
      n['read'] = true;
    }

    await prefs.setString(_key, jsonEncode(list));
  }

  /// ♻ Replace entire list (USED FOR SWIPE-TO-DELETE)
  static Future<void> replace(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list));
  }

  /// 🗑 Clear ALL notifications
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
