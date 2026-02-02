// lib/state/exam_state.dart
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

  static Timer? _timer;
  static int? _totalDays;
  static bool _initialized = false;

  static const _dateKey = 'exam_date';
  static const _totalKey = 'exam_total_days';
  static const _doneKey = 'exam_completed_notified';

  /// ✅ REQUIRED BY UI
  static bool get hasExam => examDate.value != null;

  /* ================= INIT ================= */

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    _totalDays = prefs.getInt(_totalKey);

    final raw = prefs.getString(_dateKey);
    if (raw != null) {
      final d = DateTime.tryParse(raw);
      if (d != null) await _recalculate(d);
    }

    _scheduleMidnight();
  }

  /* ================= UPDATE ================= */

  static Future<void> update(DateTime d) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized =
        DateTime(d.year, d.month, d.day);

    await prefs.setString(
        _dateKey, normalized.toIso8601String());
    await prefs.remove(_doneKey);
    await prefs.remove('exam_morning_done');

    await _recalculate(normalized);
  }

  /* ================= CORE LOGIC ================= */

  static Future<void> _recalculate(DateTime d) async {
    examDate.value = d;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final now = DateTime(today.year, today.month, today.day);
    final diff = d.difference(now).inDays;

    if (diff < 0) {
      isExamCompleted.value = true;
      isExamDay.value = false;
      daysLeft.value = 0;

      if (!(prefs.getBool(_doneKey) ?? false)) {
        await NotificationService.examCompleted();
        await prefs.setBool(_doneKey, true);
      }
      return;
    }

    if (diff == 0) {
      isExamDay.value = true;
      isExamCompleted.value = false;
      daysLeft.value = 0;

      await NotificationService.cancelDailyOnly();
      await NotificationService.scheduleExamMorningOnce(d);
      return;
    }

    isExamDay.value = false;
    isExamCompleted.value = false;
    daysLeft.value = diff;

    _totalDays ??= diff;
    await prefs.setInt(_totalKey, _totalDays!);

    await NotificationService.scheduleDaily(diff);
    await NotificationService.scheduleExamMorningOnce(d);
  }

  /* ================= MIDNIGHT TICK ================= */

  static void _scheduleMidnight() {
    _timer?.cancel();
    final now = DateTime.now();
    final next =
        DateTime(now.year, now.month, now.day + 1);

    _timer = Timer(next.difference(now), () async {
      if (examDate.value != null) {
        await _recalculate(examDate.value!);
      }
      _scheduleMidnight();
    });
  }

  /* ================= UI HELPERS ================= */

  static double progress() {
    if (_totalDays == null || _totalDays! <= 0) return 0;
    return 1 - (daysLeft.value / _totalDays!);
  }

  static Color colorForDays(int d) {
    if (d >= 45) return Colors.green;
    if (d >= 30) return Colors.orange;
    return Colors.red;
  }

  /* ================= CLEAR ================= */

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dateKey);
    await prefs.remove(_totalKey);
    await prefs.remove(_doneKey);
    await prefs.remove('exam_morning_done');

    await NotificationService.cancelAll();

    examDate.value = null;
    daysLeft.value = 0;
    isExamDay.value = false;
    isExamCompleted.value = false;
    _totalDays = null;
  }
}