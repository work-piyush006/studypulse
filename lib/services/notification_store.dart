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

  /* ================= SAVE (DEDUPED) ================= */

  static Future<void> save({
    required String title,
    required String body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    final list = raw == null
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(jsonDecode(raw));

    final alreadyExists = list.any(
      (n) => n['title'] == title && n['body'] == body,
    );

    if (!alreadyExists) {
      list.insert(0, {
        'title': title,
        'body': body,
        'time': DateTime.now().toIso8601String(),
        'read': false,
      });
    }

    _autoDeleteOld(list);
    await _sync(list);
  }

  /* ================= REPLACE (🔥 FIX) ================= */

  /// Used by NotificationInbox
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

  static bool _autoDeleteOld(List<Map<String, dynamic>> list) {
    final now = DateTime.now();
    list.removeWhere((n) {
      final time = DateTime.tryParse(n['time'] ?? '');
      if (time == null) return false;
      return now.difference(time).inDays >= 30;
    });
    return true;
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
      // launcher doesn't support badges
    }
  }
}