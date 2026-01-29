import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_badge_plus/app_badge_plus.dart';

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

    final List<Map<String, dynamic>> list =
        List<Map<String, dynamic>>.from(jsonDecode(raw));

    final changed = _autoDeleteOld(list);
    if (changed) {
      await prefs.setString(_key, jsonEncode(list));
    }

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
    final List list = raw == null ? [] : jsonDecode(raw);

    list.insert(0, {
      'title': title,
      'body': body,
      'time': DateTime.now().toIso8601String(),
      'read': false,
    });

    _autoDeleteOld(list);

    await prefs.setString(_key, jsonEncode(list));
    _updateUnread(list);
  }

  /* ================= DELETE ================= */

  static Future<void> deleteAt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;

    final List<Map<String, dynamic>> list =
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

    final List list = jsonDecode(raw);
    for (final n in list) {
      n['read'] = true;
    }

    await prefs.setString(_key, jsonEncode(list));
    _updateUnread(list);
  }

  static Future<void> replace(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    _autoDeleteOld(list);
    await prefs.setString(_key, jsonEncode(list));
    _updateUnread(list);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _updateUnread([]);
  }

  /* ================= AUTO DELETE ================= */

  static bool _autoDeleteOld(List list) {
    final now = DateTime.now();
    final before = list.length;

    list.removeWhere((n) {
      final time = DateTime.tryParse(n['time'] ?? '');
      if (time == null) return false;
      return now.difference(time).inDays >= 30;
    });

    return before != list.length;
  }

  /* ================= BADGE ================= */

  static void _updateUnread(List list) {
    final unread =
        list.where((n) => n['read'] == false).length;

    unreadNotifier.value = unread;

    try {
      if (unread == 0) {
        AppBadgePlus.removeBadge();
      } else {
        AppBadgePlus.updateBadge(unread);
      }
    } catch (_) {
      // launcher does not support badges → ignore safely
    }
  }
}
