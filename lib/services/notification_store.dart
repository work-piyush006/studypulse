import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationStore {
  static const _key = 'notifications';

  /// 🔔 REALTIME notifier for bell badge
  static final ValueNotifier<int> unreadNotifier =
      ValueNotifier<int>(0);

  /* ================= SAVE ================= */

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
    _updateUnreadCount(list);
  }

  /* ================= LOAD ================= */

  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      unreadNotifier.value = 0;
      return [];
    }

    final list = List<Map<String, dynamic>>.from(jsonDecode(raw));
    _updateUnreadCount(list);
    return list;
  }

  /* ================= READ ================= */

  static Future<void> markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;

    final List list = jsonDecode(raw);
    for (final n in list) {
      n['read'] = true;
    }

    await prefs.setString(_key, jsonEncode(list));
    unreadNotifier.value = 0;
  }

  /* ================= DELETE ================= */

  static Future<void> replace(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list));
    _updateUnreadCount(list);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    unreadNotifier.value = 0;
  }

  /* ================= INTERNAL ================= */

  static void _updateUnreadCount(List list) {
    unreadNotifier.value =
        list.where((n) => n['read'] == false).length;
  }
}
