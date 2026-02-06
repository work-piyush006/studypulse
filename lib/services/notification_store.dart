// lib/services/notification_store.dart

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

    final list = raw == null
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(jsonDecode(raw));

    _autoDeleteOld(list);
    await _sync(list);
    return list;
  }

  /* ================= SAVE ================= */

  static Future<void> save({
    required String title,
    required String body,
    required String route,
    required String source, // 'fcm' | 'local'
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    final now = DateTime.now().toIso8601String();

    final list = raw == null
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(jsonDecode(raw));

    // 🔒 Deduplicate: same route + same title + same day
    final exists = list.any((n) {
      final t = DateTime.tryParse(n['time'] ?? '');
      if (t == null) return false;

      return n['route'] == route &&
          n['title'] == title &&
          t.day == DateTime.now().day &&
          t.month == DateTime.now().month &&
          t.year == DateTime.now().year;
    });

    if (!exists) {
      list.insert(0, {
        'title': title,
        'body': body,
        'route': route,
        'source': source,
        'time': now,
        'read': false,
      });
    }

    _autoDeleteOld(list);
    await _sync(list);
  }

  /* ================= REPLACE ================= */

  static Future<void> replace(
      List<Map<String, dynamic>> list) async {
    _autoDeleteOld(list);
    await _sync(list);
  }

  /* ================= DELETE ================= */

  static Future<void> deleteAt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;

    final list =
        List<Map<String, dynamic>>.from(jsonDecode(raw));

    if (index < 0 || index >= list.length) return;

    list.removeAt(index);
    await _sync(list);
  }

  /* ================= MARK ALL READ ================= */

  static Future<void> markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;

    final list =
        List<Map<String, dynamic>>.from(jsonDecode(raw));

    for (final n in list) {
      n['read'] = true;
    }

    await _sync(list);
  }

  /* ================= CLEAR ================= */

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await _updateUnread([]);
  }

  /* ================= INTERNAL ================= */

  static Future<void> _sync(
      List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list));
    await _updateUnread(list);
  }

  static void _autoDeleteOld(List<Map<String, dynamic>> list) {
    final now = DateTime.now();

    list.removeWhere((n) {
      final time = DateTime.tryParse(n['time'] ?? '');
      if (time == null) return false;
      return now.difference(time).inDays >= 30;
    });
  }

  /* ================= BADGE ================= */

  static Future<void> _updateUnread(
      List<Map<String, dynamic>> list) async {
    final unread =
        list.where((n) => n['read'] == false).length;

    unreadNotifier.value = unread;

    try {
      await AppBadgePlus.updateBadge(unread);
    } catch (_) {
      // launcher may not support badges
    }
  }
}
