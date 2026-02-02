import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification.dart';

class ExamState {
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
  static const String _completedNotifiedKey =
      'exam_completed_notified';

  static int? _totalDays;
  static bool _initialized = false;

  /* ================= INIT ================= */

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    _totalDays = prefs.getInt(_totalKey);

    final saved = prefs.getString(_dateKey);
    if (saved != null) {
      final parsed = DateTime.tryParse(saved);
      if (parsed != null) {
        await _recalculate(parsed, fromInit: true);
      } else {
        await clear();
      }
    } else {
      _resetRuntime();
    }

    _scheduleMidnightRefresh();
  }

  /* ================= UPDATE ================= */

  static Future<void> update(DateTime date) async {
    final normalized =
        DateTime(date.year, date.month, date.day);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _dateKey, normalized.toIso8601String());

    await _recalculate(normalized, fromInit: false);
  }

  /* ================= CORE ================= */

  static Future<void> _recalculate(
    DateTime date, {
    required bool fromInit,
  }) async {
    examDate.value = date;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = target.difference(today).inDays;
    final prefs = await SharedPreferences.getInstance();

    // 🔴 Exam completed
    if (diff < 0) {
      daysLeft.value = 0;
      isExamDay.value = false;
      isExamCompleted.value = true;

      final notified =
          prefs.getBool(_completedNotifiedKey) ?? false;

      if (!notified && !fromInit) {
        await NotificationService.examCompleted();
        await prefs.setBool(_completedNotifiedKey, true);
      }
      return;
    }

    // 🟠 Exam day
    if (diff == 0) {
      daysLeft.value = 0;
      isExamDay.value = true;
      isExamCompleted.value = false;

      // SAFETY: ensure 6 AM notification exists
      await NotificationService.scheduleExamMorning(date);
      await NotificationService.cancelDaily();
      return;
    }

    // 🟢 Future exam
    isExamDay.value = false;
    isExamCompleted.value = false;
    daysLeft.value = diff;

    if (_totalDays == null) {
      _totalDays = diff;
      await prefs.setInt(_totalKey, diff);
    }

    if (!fromInit) {
      await NotificationService.scheduleDaily(daysLeft: diff);
      await NotificationService.scheduleExamMorning(date);
      await prefs.remove(_completedNotifiedKey);
    }
  }

  /* ================= MIDNIGHT ================= */

  static void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();

    final now = DateTime.now();
    final nextMidnight =
        DateTime(now.year, now.month, now.day + 1);

    _midnightTimer = Timer(
      nextMidnight.difference(now),
      () async {
        if (examDate.value != null) {
          await _recalculate(
            examDate.value!,
            fromInit: true,
          );
        }
        _scheduleMidnightRefresh();
      },
    );
  }

  /* ================= HELPERS ================= */

  static bool get hasExam => examDate.value != null;

  static double progress() {
    if (_totalDays == null || _totalDays! <= 0) return 0;
    return 1 - (daysLeft.value / _totalDays!);
  }

  static Color colorForDays(int days) {
    if (days >= 45) return Colors.green;
    if (days >= 30) return Colors.orange;
    return Colors.red;
  }

  /* ================= CLEAR ================= */

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dateKey);
    await prefs.remove(_totalKey);
    await prefs.remove(_completedNotifiedKey);

    await NotificationService.cancelDaily();
    _resetRuntime();
  }

  static void _resetRuntime() {
    examDate.value = null;
    daysLeft.value = 0;
    isExamDay.value = false;
    isExamCompleted.value = false;
    _totalDays = null;
  }
}