// lib/state/exam_state.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ExamEvent {
  examSet,
  examDay,
  examCompleted,
  examCleared,
}

class ExamState {
  static final examDate = ValueNotifier<DateTime?>(null);
  static final daysLeft = ValueNotifier<int>(0);
  static final isExamDay = ValueNotifier(false);
  static final isExamCompleted = ValueNotifier(false);

  /// 🔔 EVENT HOOK (for notifications / server sync)
  static final event = ValueNotifier<ExamEvent?>(null);

  static Timer? _timer;
  static int? _totalDays;
  static bool _initialized = false;

  static const _dateKey = 'exam_date';
  static const _totalKey = 'exam_total_days';
  static const _completedKey = 'exam_completed_flag';

  /* ================= PUBLIC ================= */

  static bool get hasExam => examDate.value != null;

  static double progress() {
    if (_totalDays == null || _totalDays == 0) return 0;
    return 1 - (daysLeft.value / _totalDays!);
  }

  static Color colorForDays(int d) {
    if (d >= 45) return Colors.green;
    if (d >= 30) return Colors.orange;
    return Colors.red;
  }

  /* ================= INIT ================= */

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();

    _totalDays = prefs.getInt(_totalKey);

    final raw = prefs.getString(_dateKey);
    if (raw != null) {
      final d = DateTime.tryParse(raw);
      if (d != null) {
        _recalculate(d);
      }
    }

    _scheduleMidnight();
  }

  /* ================= UPDATE ================= */

  static Future<void> update(DateTime d) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = DateTime(d.year, d.month, d.day);

    await prefs.setString(_dateKey, normalized.toIso8601String());
    await prefs.remove(_completedKey);

    event.value = ExamEvent.examSet;
    _recalculate(normalized);
  }

  /* ================= CORE ================= */

  static void _recalculate(DateTime d) async {
    examDate.value = d;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = d.difference(today).inDays;

    // Exam already passed
    if (diff < 0) {
      final completed = prefs.getBool(_completedKey) ?? false;

      daysLeft.value = 0;
      isExamDay.value = false;
      isExamCompleted.value = true;

      if (!completed) {
        await prefs.setBool(_completedKey, true);
        event.value = ExamEvent.examCompleted;
      }
      return;
    }

    // Exam today
    if (diff == 0) {
      daysLeft.value = 0;
      isExamDay.value = true;
      isExamCompleted.value = false;

      event.value = ExamEvent.examDay;
      return;
    }

    // Future exam
    isExamDay.value = false;
    isExamCompleted.value = false;
    daysLeft.value = diff;

    _totalDays ??= diff;
    prefs.setInt(_totalKey, _totalDays!);
  }

  /* ================= MIDNIGHT ================= */

  static void _scheduleMidnight() {
    _timer?.cancel();

    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);

    _timer = Timer(next.difference(now), () {
      if (examDate.value != null) {
        _recalculate(examDate.value!);
      }
      _scheduleMidnight();
    });
  }

  /* ================= CLEAR ================= */

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dateKey);
    await prefs.remove(_totalKey);
    await prefs.remove(_completedKey);

    examDate.value = null;
    daysLeft.value = 0;
    isExamDay.value = false;
    isExamCompleted.value = false;
    _totalDays = null;

    event.value = ExamEvent.examCleared;
  }
}
