// lib/state/exam_state.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification.dart';

class ExamState {
  /* ================= NOTIFIERS ================= */

  static final ValueNotifier<DateTime?> examDate =
      ValueNotifier<DateTime?>(null);

  static final ValueNotifier<int> daysLeft =
      ValueNotifier<int>(0);

  static final ValueNotifier<bool> isExamDay =
      ValueNotifier<bool>(false);

  static final ValueNotifier<bool> isExamCompleted =
      ValueNotifier<bool>(false);

  /* ================= INTERNAL ================= */

  static Timer? _midnightTimer;

  static const String _dateKey = 'exam_date';
  static const String _totalKey = 'exam_total_days';

  static int? _totalDays; // cached baseline

  static bool _initialized = false; // 🔒 HARD GUARD

  /* ================= INIT ================= */

  /// Safe to call multiple times.
  /// Will only execute once per app lifecycle.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
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

  /// Called ONLY when user selects a date
  static Future<void> update(DateTime date) async {
    final normalized =
        DateTime(date.year, date.month, date.day);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateKey, normalized.toIso8601String());

    await _recalculate(normalized, fromInit: false);
  }

  /* ================= CORE LOGIC ================= */

  static Future<void> _recalculate(
    DateTime date, {
    required bool fromInit,
  }) async {
    examDate.value = date;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = target.difference(today).inDays;

    // 🔴 Exam passed
    if (diff < 0) {
      daysLeft.value = 0;
      isExamDay.value = false;
      isExamCompleted.value = true;

      if (!fromInit) {
        await clear();
        await NotificationService.instant(
          title: '🎉 Exam Completed',
          body: 'Any next exam left?\nStart preparing today 📘',
          save: true,
          route: '/exam',
        );
      }
      return;
    }

    // 🟠 Exam day
    if (diff == 0) {
      daysLeft.value = 0;
      isExamDay.value = true;
      isExamCompleted.value = false;

      await NotificationService.cancelDaily();

      if (!fromInit) {
        await NotificationService.instant(
          title: '🤞 Best of Luck!',
          body: 'Your exam is today.\nYou’ve got this 💪',
          save: true,
          route: '/exam',
        );
      }
      return;
    }

    // 🟢 Future exam
    isExamDay.value = false;
    isExamCompleted.value = false;
    daysLeft.value = diff;

    final prefs = await SharedPreferences.getInstance();

    if (_totalDays == null) {
      _totalDays = diff;
      await prefs.setInt(_totalKey, diff);
    }

    // 🔥 Schedule ONLY on user action
    if (!fromInit) {
      await NotificationService.scheduleDaily(daysLeft: diff);
    }
  }

  /* ================= MIDNIGHT REFRESH ================= */

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
            fromInit: true, // 🔒 NEVER reschedule here
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