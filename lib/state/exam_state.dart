import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExamState {
  /// 🔥 SINGLE SOURCE OF TRUTH
  static final ValueNotifier<DateTime?> examDate =
      ValueNotifier<DateTime?>(null);

  static final ValueNotifier<int> daysLeft =
      ValueNotifier<int>(0);

  static final ValueNotifier<bool> isExamDay =
      ValueNotifier<bool>(false);

  static int _initialTotalDays = 0;
  static Timer? _midnightTimer;

  /* ================= INIT ================= */

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('exam_date');

    if (saved != null) {
      update(DateTime.parse(saved));
    } else {
      _reset();
    }

    _scheduleMidnightRefresh();
  }

  /* ================= UPDATE ================= */

  static void update(DateTime? date) {
    examDate.value = date;

    if (date == null) {
      _reset();
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = target.difference(today).inDays;

    // ❌ Exam passed → AUTO RESET
    if (diff < 0) {
      clear();
      return;
    }

    // 🔥 EXAM DAY
    if (diff == 0) {
      daysLeft.value = 0;
      isExamDay.value = true;
      return;
    }

    // ✅ NORMAL COUNTDOWN
    isExamDay.value = false;
    daysLeft.value = diff;

    if (_initialTotalDays == 0) {
      _initialTotalDays = diff;
    }
  }

  /* ================= MIDNIGHT REFRESH ================= */

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

  /* ================= PROGRESS ================= */

  static double progress() {
    if (_initialTotalDays <= 0) return 0;
    return 1 - (daysLeft.value / _initialTotalDays);
  }

  /* ================= COLOR ================= */

  static Color colorForDays(int days) {
    if (days >= 90) return Colors.green;
    if (days >= 30) return Colors.orange;
    return Colors.red;
  }

  /* ================= CLEAR ================= */

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('exam_date');
    await prefs.remove('exam_first_notification_done');
    _reset();
  }

  static void _reset() {
    examDate.value = null;
    daysLeft.value = 0;
    isExamDay.value = false;
    _initialTotalDays = 0;
  }
}