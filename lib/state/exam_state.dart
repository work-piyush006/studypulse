// lib/state/exam_state.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExamState {
  /* ================= STATE ================= */

  static final ValueNotifier<DateTime?> examDate =
      ValueNotifier<DateTime?>(null);

  static final ValueNotifier<int> daysLeft =
      ValueNotifier<int>(0);

  static final ValueNotifier<bool> isExamDay =
      ValueNotifier<bool>(false);

  static final ValueNotifier<bool> isExamCompleted =
      ValueNotifier<bool>(false);

  static Timer? _midnightTimer;

  static const String _dateKey = 'exam_date';
  static const String _totalKey = 'exam_total_days';

  /* ================= INIT ================= */

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_dateKey);

    if (savedDate != null) {
      await update(DateTime.parse(savedDate));
    } else {
      _reset();
    }

    _scheduleMidnightRefresh();
  }

  /* ================= UPDATE ================= */

  static Future<void> update(DateTime? date) async {
    final prefs = await SharedPreferences.getInstance();

    if (date == null) {
      await clear();
      return;
    }

    examDate.value = date;
    isExamCompleted.value = false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = target.difference(today).inDays;

    // 🔴 Exam already passed
    if (diff < 0) {
      await clear();
      isExamCompleted.value = true;
      return;
    }

    // 🟡 Exam day
    if (diff == 0) {
      daysLeft.value = 0;
      isExamDay.value = true;
      return;
    }

    // 🟢 Normal countdown
    isExamDay.value = false;
    daysLeft.value = diff;

    if (!prefs.containsKey(_totalKey)) {
      await prefs.setInt(_totalKey, diff);
    }
  }

  /* ================= PROGRESS (SYNC) ================= */

  static double progress() {
    if (daysLeft.value <= 0) return 0;

    return _totalDays <= 0
        ? 0
        : 1 - (daysLeft.value / _totalDays);
  }

  static int get _totalDays =>
      _cachedTotalDays ?? 0;

  static int? _cachedTotalDays;

  /* ================= MIDNIGHT REFRESH ================= */

  static void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();

    final now = DateTime.now();
    final nextMidnight =
        DateTime(now.year, now.month, now.day + 1);

    final duration = nextMidnight.difference(now);

    _midnightTimer = Timer(duration, () async {
      final prefs = await SharedPreferences.getInstance();
      _cachedTotalDays = prefs.getInt(_totalKey);

      if (examDate.value != null) {
        await update(examDate.value);
      }
      _scheduleMidnightRefresh();
    });
  }

  /* ================= HELPERS ================= */

  static bool get hasExam => examDate.value != null;

  static Color colorForDays(int days) {
    if (days >= 90) return Colors.green;
    if (days >= 30) return Colors.orange;
    return Colors.red;
  }

  /* ================= CLEAR ================= */

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dateKey);
    await prefs.remove(_totalKey);
    _reset();
  }

  static void _reset() {
    examDate.value = null;
    daysLeft.value = 0;
    isExamDay.value = false;
    isExamCompleted.value = false;
    _cachedTotalDays = null;
  }
}