import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

class NotificationStore {
  static const _key = 'notifications';

  static final ValueNotifier<int> unreadNotifier =
      ValueNotifier<int>(0);

  /* ================= GET ALL ================= */

  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null) {
      _updateUnread([]);
      return [];
    }

    final list =
        List<Map<String, dynamic>>.from(jsonDecode(raw));

    _autoDeleteOld(list);
    _updateUnread(list);
    return list;
  }

  /* ================= SAVE ================= */

  static Future<void> save({
    required String title,
    required String body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final list = raw == null ? [] : jsonDecode(raw);

    list.insert(0, {
      'title': title,
      'body': body,
      'time': DateTime.now().toIso8601String(),
      'read': false,
    });

    await prefs.setString(_key, jsonEncode(list));
    _autoDeleteOld(list);
    _updateUnread(list);
  }

  /* ================= DELETE ONE ================= */

  static Future<void> deleteAt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;

    final list =
        List<Map<String, dynamic>>.from(jsonDecode(raw));

    if (index < 0 || index >= list.length) return;

    list.removeAt(index);

    await prefs.setString(_key, jsonEncode(list));
    _updateUnread(list);
  }

  /* ================= MARK ALL READ ================= */

  static Future<void> markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;

    final list = jsonDecode(raw);
    for (final n in list) {
      n['read'] = true;
    }

    await prefs.setString(_key, jsonEncode(list));
    _updateUnread(list);
  }

  /* ================= REPLACE ================= */

  static Future<void> replace(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list));
    _updateUnread(list);
  }

  /* ================= CLEAR ALL ================= */

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _updateUnread([]);
  }

  /* ================= AUTO DELETE (30 DAYS) ================= */

  static void _autoDeleteOld(List list) {
    final now = DateTime.now();

    list.removeWhere((n) {
      final time = DateTime.tryParse(n['time'] ?? '');
      if (time == null) return false;
      return now.difference(time).inDays >= 30;
    });
  }

  /* ================= BADGE + UNREAD ================= */

  static void _updateUnread(List list) {
    final unread =
        list.where((n) => n['read'] == false).length;

    unreadNotifier.value = unread;

    if (unread == 0) {
      FlutterAppBadger.removeBadge();
    } else {
      FlutterAppBadger.updateBadgeCount(unread);
    }
  }
}
