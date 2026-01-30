import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExamState {
  /// 🔥 SINGLE SOURCE OF TRUTH
  static final ValueNotifier<DateTime?> examDate =
      ValueNotifier<DateTime?>(null);

  static final ValueNotifier<int> daysLeft =
      ValueNotifier<int>(0);

  static int _totalDays = 0;
  static Timer? _midnightTimer;

  /// 🔥 MUST CALL IN main.dart BEFORE runApp()
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('exam_date');

    if (saved != null) {
      update(DateTime.parse(saved));
    } else {
      examDate.value = null;
      daysLeft.value = 0;
      _totalDays = 0;
    }

    _scheduleMidnightRefresh();
  }

  /// 🔥 CENTRAL UPDATE METHOD (BUG FIXED)
  static void update(DateTime? date) {
    examDate.value = date;

    if (date == null) {
      daysLeft.value = 0;
      _totalDays = 0;
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = target.difference(today).inDays;
    daysLeft.value = diff < 0 ? 0 : diff;

    // ✅ FIX: ALWAYS reset total days when date changes
    _totalDays = daysLeft.value;
  }

  /// 🌙 AUTO UPDATE AT MIDNIGHT (NO APP RESTART NEEDED)
  static void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();

    final now = DateTime.now();
    final nextMidnight =
        DateTime(now.year, now.month, now.day + 1);

    final duration = nextMidnight.difference(now);

    _midnightTimer = Timer(duration, () {
      if (examDate.value != null) {
        update(examDate.value);
      }
      _scheduleMidnightRefresh();
    });
  }

  /// 📊 PROGRESS FOR LINEAR PROGRESS BAR (0.0 → 1.0)
  static double progress() {
    if (_totalDays <= 0) return 0;
    return 1 - (daysLeft.value / _totalDays);
  }

  /// 🎨 COLOR LOGIC (USED EVERYWHERE)
  static Color colorForDays(int days) {
    if (days >= 45) return Colors.green;
    if (days >= 30) return Colors.orange;
    return Colors.red;
  }

  /// 🔘 CANCEL COUNTDOWN (RESET EVERYTHING)
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('exam_date');
    await prefs.remove('exam_first_notification_done');

    examDate.value = null;
    daysLeft.value = 0;
    _totalDays = 0;
  }
}