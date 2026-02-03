// lib/state/exam_state.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification.dart';

class ExamState {
  static final examDate = ValueNotifier<DateTime?>(null);
  static final daysLeft = ValueNotifier<int>(0);
  static final isExamDay = ValueNotifier(false);
  static final isExamCompleted = ValueNotifier(false);

  static Timer? _timer;
  static int? _totalDays;
  static bool _initialized = false;

  static const _dateKey = 'exam_date';
  static const _totalKey = 'exam_total_days';
  static const _completedKey = 'exam_completed_notified';

  static bool get hasExam => examDate.value != null;

  /* ================= INIT ================= */

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dateKey);

    if (raw != null) {
      final d = DateTime.tryParse(raw);
      if (d != null) {
        await _recalculate(d, fromUser: false);
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

    await _recalculate(normalized, fromUser: true);
  }

  /* ================= CORE ================= */

  static Future<void> _recalculate(
    DateTime d, {
    required bool fromUser,
  }) async {
    examDate.value = d;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = d.difference(today).inDays;

    // 🔴 Exam completed
    if (diff < 0) {
      daysLeft.value = 0;
      isExamDay.value = false;
      isExamCompleted.value = true;

      if (!(prefs.getBool(_completedKey) ?? false)) {
        await NotificationService.examCompleted();
        await prefs.setBool(_completedKey, true);
      }
      return;
    }

    // 🟠 Exam day
    if (diff == 0) {
      daysLeft.value = 0;
      isExamDay.value = true;
      isExamCompleted.value = false;

      if (fromUser) {
        await NotificationService.instant(
          title: '🤞 Best of Luck!',
          body: 'Your exam is today.\nYou’ve got this 💪📘',
          save: true,
          route: '/exam',
        );
      }

      await NotificationService.scheduleExamMorning(d);
      await NotificationService.cancelDaily();
      return;
    }

    // 🟢 Future exam
    isExamDay.value = false;
    isExamCompleted.value = false;
    daysLeft.value = diff;

    _totalDays ??= diff;
    await prefs.setInt(_totalKey, _totalDays!);

    if (fromUser) {
      await NotificationService.scheduleDaily(diff);
      await NotificationService.scheduleExamMorning(d);
    }
  }

  /* ================= MIDNIGHT ================= */

  static void _scheduleMidnight() {
    _timer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);

    _timer = Timer(next.difference(now), () async {
      if (examDate.value != null) {
        await _recalculate(examDate.value!, fromUser: false);
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

    await NotificationService.cancelAll();

    examDate.value = null;
    daysLeft.value = 0;
    isExamDay.value = false;
    isExamCompleted.value = false;
    _totalDays = null;
  }

  static double progress() =>
      _totalDays == null || _totalDays == 0
          ? 0
          : 1 - (daysLeft.value / _totalDays!);

  static Color colorForDays(int d) {
    if (d >= 45) return Colors.green;
    if (d >= 30) return Colors.orange;
    return Colors.red;
  }
}